<?php

namespace App\Services;

// use App\Models\AdSpaces;
use App\Models\BreakingNewsView;
use App\Models\FeaturedSectionRssFeed;
use App\Models\FeedItem;
use App\Models\News_image;
use App\Models\UserCategory;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class FeaturedSectionService
{
    private string $toDate;
    private int|float $nearestLocationMeasure;

    public function __construct(string $toDate, int|float $nearestLocationMeasure)
    {
        $this->toDate = $toDate;
        $this->nearestLocationMeasure = $nearestLocationMeasure;
    }

    // -------------------------------------------------------------------------
    // Base query helpers
    // -------------------------------------------------------------------------

    /**
     * Build the standard distance expression used in SELECT.
     */
    private function distanceExpr(float $latitude, float $longitude): \Illuminate\Database\Query\Expression
    {
        return DB::raw(
            "SQRT(POW(111.2 * (tbl_location.latitude - {$latitude}), 2) + " .
            "POW(111.2 * ({$longitude} - tbl_location.longitude) * " .
            "COS(tbl_location.latitude / 57.3), 2)) AS distance"
        );
    }

    /**
     * Apply the published_date / created_at date constraint.
     * Handles both: published_date IS NOT NULL (use it) or NULL (fall back to created_at).
     */
    private function applyDateConstraints(\Illuminate\Database\Query\Builder $query): \Illuminate\Database\Query\Builder
    {
        $toDate = $this->toDate;
        return $query->where(function ($q) use ($toDate) {
            $q->where(function ($subq) use ($toDate) {
                $subq->whereNotNull('tbl_news.published_date')
                    ->where('tbl_news.published_date', '<=', $toDate);
            })->orWhere(function ($subq) use ($toDate) {
                $subq->whereNull('tbl_news.published_date')
                    ->whereDate('tbl_news.created_at', '<=', $toDate);
            });
        });
    }

    /**
     * Apply the show_till visibility constraint.
     */
    private function applyShowTillConstraint(\Illuminate\Database\Query\Builder $query): \Illuminate\Database\Query\Builder
    {
        $toDate = $this->toDate;
        return $query->where(function ($q) use ($toDate) {
            $q->where('tbl_news.show_till', '>=', $toDate)
                ->orWhereRaw("CAST(tbl_news.show_till AS CHAR(20)) = '0000-00-00'");
        });
    }

    /**
     * Apply category / subcategory filters based on section settings.
     */
    private function applyCategoryFilter(\Illuminate\Database\Query\Builder $query, object $row): \Illuminate\Database\Query\Builder
    {
        $hasCats = !empty($row->category_ids);
        $hasSubs = !empty($row->subcategory_ids);

        $categoryIds = $hasCats ? explode(',', $row->category_ids) : [];
        $subcategoryIds = $hasSubs ? explode(',', $row->subcategory_ids) : [];

        // Filter out empty values
        $categoryIds = array_filter($categoryIds, fn($id) => !empty(trim($id)));
        $subcategoryIds = array_filter($subcategoryIds, fn($id) => !empty(trim($id)));

        if (!empty($categoryIds) && !empty($subcategoryIds)) {
            $query->where(function ($q1) use ($categoryIds, $subcategoryIds) {
                $q1->whereIn('tbl_news.category_id', $categoryIds)
                    ->orWhereIn('tbl_news.subcategory_id', $subcategoryIds);
            });
        } elseif (!empty($categoryIds)) {
            $query->whereIn('tbl_news.category_id', $categoryIds);
        } elseif (!empty($subcategoryIds)) {
            $query->whereIn('tbl_news.subcategory_id', $subcategoryIds);
        }

        return $query;
    }

    /**
     * Conditionally apply the geo-distance HAVING clause.
     */
    private function applyLocationFilter(\Illuminate\Database\Query\Builder $query, float $latitude, float $longitude): \Illuminate\Database\Query\Builder
    {
        if ($latitude != 0 && $longitude != 0) {
            $measure = $this->nearestLocationMeasure;
            $query->havingRaw("distance < {$measure} OR tbl_news.location_id = 0");
        }
        return $query;
    }

    /**
     * Get count then paginate. Returns [$result_count, $results].
     */
    private function paginate(\Illuminate\Database\Query\Builder $query, int $offset, int $limit, string $orderBy, string $direction = 'DESC'): array
    {
        $result_count = $query->count();
        $results = $query->skip($offset)->take($limit)->orderBy($orderBy, $direction)->get();
        return [$result_count, $results];
    }

    /**
     * Build the standard tbl_news base query (no filter-specific joins yet).
     * Uses leftJoin for category so that news without a category still appear.
     */
    private function buildBaseNewsQuery(int $languageId, float $latitude, float $longitude, bool $innerJoinCategory = false): \Illuminate\Database\Query\Builder
    {
        $query = DB::table('tbl_news')
            ->select(
                'tbl_news.*',
                'tbl_category.category_name',
                DB::raw('IFNULL(tbl_subcategory.subcategory_name, "") AS subcategory_name'),
                $this->distanceExpr($latitude, $longitude)
            )
            ->where('tbl_news.is_draft', 0)
            ->where('tbl_news.status', 1)
            ->where('tbl_news.language_id', $languageId)
            ->leftJoin('tbl_subcategory', 'tbl_news.subcategory_id', '=', 'tbl_subcategory.id')
            ->leftJoin('tbl_location', 'tbl_news.location_id', '=', 'tbl_location.id');

        if ($innerJoinCategory) {
            $query->join('tbl_category', 'tbl_news.category_id', '=', 'tbl_category.id');
        } else {
            $query->leftJoin('tbl_category', 'tbl_news.category_id', '=', 'tbl_category.id');
        }

        $this->applyDateConstraints($query);
        $this->applyShowTillConstraint($query);

        return $query;
    }

    // -------------------------------------------------------------------------
    // Filter type resolvers – news / videos / author_news
    // -------------------------------------------------------------------------

    private function resolveMostCommented(object $row, int $languageId, float $latitude, float $longitude, int $offset, int $limit): array
    {
        $query = $this->buildBaseNewsQuery($languageId, $latitude, $longitude, innerJoinCategory: true)
            ->addSelect('tbl_comment.newscount')
            ->join(
                DB::raw('(SELECT news_id, COUNT(*) AS newscount FROM tbl_comment GROUP BY news_id) AS tbl_comment'),
                fn($join) => $join->on('tbl_news.id', '=', 'tbl_comment.news_id')
            );

        $this->applyCategoryFilter($query, $row);

        if ($row->news_type === 'videos' && $row->videos_type === 'news') {
            $query->where('tbl_news.description', '!=', '')
                ->whereIn('tbl_news.content_type', ['video_upload', 'video_youtube', 'video_other']);
        }

        $this->applyLocationFilter($query, $latitude, $longitude);

        return $this->paginate($query, $offset, $limit, 'tbl_comment.newscount');
    }

    private function resolveRecentlyAdded(object $row, int $languageId, float $latitude, float $longitude, int $offset, int $limit): array
    {
        $query = $this->buildBaseNewsQuery($languageId, $latitude, $longitude);

        // Apply category filter first
        $this->applyCategoryFilter($query, $row);

        // Apply location filter
        $this->applyLocationFilter($query, $latitude, $longitude);

        // Apply additional filters based on news_type
        if ($row->news_type === 'news') {
            $query->where('tbl_news.description', '!=', '');
        } elseif ($row->news_type === 'videos' && $row->videos_type === 'news') {
            $query->whereIn('tbl_news.content_type', ['video_upload', 'video_youtube', 'video_other']);
        } else {
            // Handle other cases (e.g., breaking_news)
            $breaking = DB::table('tbl_breaking_news')
                ->select('tbl_breaking_news.*')
                ->where('tbl_breaking_news.language_id', $languageId)
                ->whereIn('tbl_breaking_news.content_type', ['video_upload', 'video_youtube', 'video_other']);

            $result_count = (clone $breaking)->count();
            $results = (clone $breaking)->skip($offset)->take($limit)->orderBy('tbl_breaking_news.id', 'DESC')->get();
            return [$result_count, $results];
        }

        return $this->paginate($query, $offset, $limit, 'tbl_news.id');
    }

    private function resolveMostViewed(object $row, int $languageId, float $latitude, float $longitude, int $offset, int $limit): array
    {
        if ($row->news_type === 'videos' && $row->videos_type === 'breaking_news') {
            $breaking = DB::table('tbl_breaking_news')
                ->select('tbl_breaking_news.*', 'tbl_breaking_news_view.viewcount')
                ->where('tbl_breaking_news.language_id', $languageId)
                ->whereIn('tbl_breaking_news.content_type', ['video_upload', 'video_youtube', 'video_other'])
                ->join(
                    DB::raw('(SELECT breaking_news_id, COUNT(*) AS viewcount FROM tbl_breaking_news_view GROUP BY breaking_news_id) AS tbl_breaking_news_view'),
                    fn($join) => $join->on('tbl_breaking_news.id', '=', 'tbl_breaking_news_view.breaking_news_id')
                );

            $result_count = (clone $breaking)->count();
            $results = (clone $breaking)->skip($offset)->take($limit)->orderBy('tbl_breaking_news_view.viewcount', 'DESC')->get();
            return [$result_count, $results];
        }

        $query = $this->buildBaseNewsQuery($languageId, $latitude, $longitude, innerJoinCategory: true)
            ->addSelect('tbl_news_view.viewcount')
            ->join(
                DB::raw('(SELECT news_id, COUNT(*) AS viewcount FROM tbl_news_view GROUP BY news_id) AS tbl_news_view'),
                fn($join) => $join->on('tbl_news.id', '=', 'tbl_news_view.news_id')
            );

        $this->applyCategoryFilter($query, $row);
        $this->applyLocationFilter($query, $latitude, $longitude);

        if ($row->news_type === 'news') {
            $query->where('tbl_news.description', '!=', '');
        }
        if ($row->news_type === 'videos') {
            $query->whereIn('tbl_news.content_type', ['video_upload', 'video_youtube', 'video_other']);
        }

        return $this->paginate($query, $offset, $limit, 'tbl_news_view.viewcount');
    }

    private function resolveMostFavorite(object $row, int $languageId, float $latitude, float $longitude, int $offset, int $limit): array
    {
        $query = $this->buildBaseNewsQuery($languageId, $latitude, $longitude, innerJoinCategory: true)
            ->addSelect('tbl_bookmark.newscount')
            ->where('tbl_news.description', '!=', '')
            ->join(
                DB::raw('(SELECT news_id, COUNT(*) AS newscount FROM tbl_bookmark GROUP BY news_id) AS tbl_bookmark'),
                fn($join) => $join->on('tbl_news.id', '=', 'tbl_bookmark.news_id')
            );

        if ($row->news_type === 'videos') {
            $query->whereIn('tbl_news.content_type', ['video_upload', 'video_youtube', 'video_other']);
        }

        $this->applyCategoryFilter($query, $row);
        $this->applyLocationFilter($query, $latitude, $longitude);

        return $this->paginate($query, $offset, $limit, 'tbl_bookmark.newscount');
    }

    private function resolveMostLike(object $row, int $languageId, float $latitude, float $longitude, int $offset, int $limit): array
    {
        $query = $this->buildBaseNewsQuery($languageId, $latitude, $longitude, innerJoinCategory: true)
            ->addSelect('tbl_news_like.likecount')
            ->where('tbl_news.description', '!=', '')
            ->join(
                DB::raw('(SELECT news_id, COUNT(*) AS likecount FROM tbl_news_like WHERE status="1" GROUP BY news_id) AS tbl_news_like'),
                fn($join) => $join->on('tbl_news.id', '=', 'tbl_news_like.news_id')
            );

        $this->applyCategoryFilter($query, $row);

        if ($row->news_type === 'videos') {
            $query->whereIn('tbl_news.content_type', ['video_upload', 'video_youtube', 'video_other']);
        }

        $this->applyLocationFilter($query, $latitude, $longitude);

        return $this->paginate($query, $offset, $limit, 'tbl_news_like.likecount');
    }

    private function resolveCustom(object $row, int $languageId, float $latitude, float $longitude, int $offset, int $limit): array
    {
        if ($row->news_type === 'videos' && $row->videos_type === 'breaking_news') {
            $breaking = DB::table('tbl_breaking_news')
                ->select('tbl_breaking_news.*')
                ->whereIn('tbl_breaking_news.content_type', ['video_upload', 'video_youtube', 'video_other'])
                ->whereIn('tbl_breaking_news.id', explode(',', $row->news_ids))
                ->where('tbl_breaking_news.language_id', $languageId);

            $result_count = (clone $breaking)->count();
            $results = (clone $breaking)->skip($offset)->take($limit)->orderBy('tbl_breaking_news.id', 'DESC')->get();
            return [$result_count, $results];
        }

        $query = $this->buildBaseNewsQuery($languageId, $latitude, $longitude)
            ->where('tbl_news.status', 1)
            ->whereIn('tbl_news.id', explode(',', $row->news_ids));

        $this->applyLocationFilter($query, $latitude, $longitude);

        if ($row->news_type === 'videos' && $row->videos_type === 'news') {
            $query->whereIn('tbl_news.content_type', ['video_upload', 'video_youtube', 'video_other']);
        }

        return $this->paginate($query, $offset, $limit, 'tbl_news.id');
    }

    // -------------------------------------------------------------------------
    // Public resolvers (called from controller)
    // -------------------------------------------------------------------------

    /**
     * Resolve news / videos / author_news results.
     *
     * @return array [$result_count, $results]
     */
    public function resolveNewsResults(object $row, int $languageId, float $latitude, float $longitude, int $offset, int $limit): array
    {
        return match ($row->filter_type) {
            'most_commented'  => $this->resolveMostCommented($row, $languageId, $latitude, $longitude, $offset, $limit),
            'recently_added'  => $this->resolveRecentlyAdded($row, $languageId, $latitude, $longitude, $offset, $limit),
            'most_viewed'     => $this->resolveMostViewed($row, $languageId, $latitude, $longitude, $offset, $limit),
            'most_favorite'   => $this->resolveMostFavorite($row, $languageId, $latitude, $longitude, $offset, $limit),
            'most_like'       => $this->resolveMostLike($row, $languageId, $latitude, $longitude, $offset, $limit),
            'custom'          => $this->resolveCustom($row, $languageId, $latitude, $longitude, $offset, $limit),
            default           => [0, collect()],
        };
    }

    /**
     * Resolve breaking_news results.
     *
     * @return array [$result_count, $results]
     */
    public function resolveBreakingNewsResults(object $row, int $languageId, int $offset, int $limit): array
    {
        switch ($row->filter_type) {
            case 'recently_added':
                $query = DB::table('tbl_breaking_news')->where('language_id', $languageId);
                $result_count = (clone $query)->count();
                $results = (clone $query)->skip($offset)->take($limit)->orderBy('tbl_breaking_news.id', 'DESC')->get();
                return [$result_count, $results];

            case 'most_viewed':
                $query = DB::table('tbl_breaking_news')
                    ->select('tbl_breaking_news.*')
                    ->join(
                        DB::raw('(SELECT breaking_news_id, COUNT(*) AS viewcount FROM tbl_breaking_news_view GROUP BY breaking_news_id) AS tbl_breaking_news_view'),
                        fn($join) => $join->on('tbl_breaking_news_view.breaking_news_id', '=', 'tbl_breaking_news.id')
                    )
                    ->where('tbl_breaking_news.language_id', $languageId);
                $result_count = (clone $query)->count();
                $results = (clone $query)->skip($offset)->take($limit)->orderBy('tbl_breaking_news_view.viewcount', 'DESC')->get();
                return [$result_count, $results];

            case 'custom':
                $query = DB::table('tbl_breaking_news')
                    ->whereIn('id', explode(',', $row->news_ids))
                    ->where('language_id', $languageId);
                $result_count = (clone $query)->count();
                $results = (clone $query)->skip($offset)->take($limit)->orderBy('id', 'DESC')->get();
                return [$result_count, $results];

            default:
                return [0, collect()];
        }
    }

    /**
     * Resolve user-choice results (based on user's preferred categories).
     *
     * @return array [$result_count, $results]
     */
    public function resolveUserChoiceResults(int $languageId, float $latitude, float $longitude, int $offset, int $limit): array
    {
        if (!Auth::check()) {
            return [0, collect()];
        }

        $userCategory = UserCategory::select('id', 'category_id')
            ->where('user_id', Auth::id())
            ->first();

        if (!$userCategory) {
            return [0, collect()];
        }

        $query = $this->buildBaseNewsQuery($languageId, $latitude, $longitude, innerJoinCategory: true)
            ->whereIn('tbl_news.category_id', explode(',', $userCategory->category_id));

        $this->applyLocationFilter($query, $latitude, $longitude);

        return $this->paginate($query, $offset, $limit, 'tbl_news.id');
    }

    /**
     * Resolve rss_feeds_news results.
     *
     * @return array [$result_count, $results]
     */
    public function resolveRssFeedsResults(object $row, int $languageId, int $offset, int $limit): array
    {
        $rssSource = FeaturedSectionRssFeed::where('featured_section_id', $row->id)->get();

        // direcly fetching from rss_feed table
        $rssFeeds = FeedItem::whereIn('rss_source_id' , $rssSource->pluck('rss_feed_id'));
        // Sort newest first
        $rssFeeds = $rssFeeds->orderBy('published_at', 'DESC');

        // totol count
        $result_count = $rssFeeds->count();

        // getting data
        $rssFeeds = $rssFeeds->skip($offset)->take($limit)->get();

        // paginated items
        $paginatedItems = $rssFeeds;

        return [$result_count, $paginatedItems];
    }

    // -------------------------------------------------------------------------
    // Item formatters (called per-row inside the results loop)
    // -------------------------------------------------------------------------

    /**
     * Resolve image URL (news/ prefix) and galleries for a regular news item.
     * Modifies the stdClass object in-place (DB raw results are stdClass).
     */
    public function formatNewsItem(object $row2, \Closure $getNewsData): object
    {
        $row2 = $getNewsData($row2, $row2->id);

        if ($row2->content_type === 'video_upload' && !empty($row2->content_value)) {
            $cv = strpos($row2->content_value, 'news_video/') === false
                ? 'news_video/' . $row2->content_value
                : $row2->content_value;
            $row2->content_value = url(Storage::url($cv));
        }

        $imagePath = (!empty($row2->image) && strpos($row2->image, 'news/') === false)
            ? 'news/' . $row2->image
            : $row2->image;
        $row2->image = url(Storage::url($imagePath));

        $images = News_image::with('news')->where('news_id', $row2->id)->get();
        $row2->images = $images->map(fn($img) => [
            'other_image' => url(Storage::url($img->getOtherImagePathAttribute())),
        ])->toArray();

        $row2->read_time = ReadTimeService::estimate($row2->description ?? null);

        return $row2;
    }

    /**
     * Format a breaking news item (image URL, video content URL, total_views).
     */
    public function formatBreakingNewsItem(object $row2): object
    {
        $imagePath = (!empty($row2->image) && strpos($row2->image, 'breaking_news/') === false)
            ? 'breaking_news/' . $row2->image
            : $row2->image;
        $row2->image = url(Storage::url($imagePath));

        if ($row2->content_type === 'video_upload' && !empty($row2->content_value)) {
            $cv = strpos($row2->content_value, 'breaking_news_video/') === false
                ? 'breaking_news_video/' . $row2->content_value
                : $row2->content_value;
            $row2->content_value = url(Storage::url($cv));
        }

        $row2->total_views = BreakingNewsView::where('breaking_news_id', $row2->id)->count('id');

        $row2->read_time = ReadTimeService::estimate($row2->description ?? null);
        return $row2;
    }

    /**
     * Format a video news item (news-sourced video).
     */
    public function formatVideoNewsItem(object $row2, \Closure $getNewsData): object
    {
        $row2 = $getNewsData($row2, $row2->id);

        $imagePath = (!empty($row2->image) && strpos($row2->image, 'news/') === false)
            ? 'news/' . $row2->image
            : $row2->image;
        $row2->image = url(Storage::url($imagePath));

        if ($row2->content_type === 'video_upload' && !empty($row2->content_value)) {
            $cv = strpos($row2->content_value, 'news_video/') === false
                ? 'news_video/' . $row2->content_value
                : $row2->content_value;
            $row2->content_value = url(Storage::url($cv));
        }

        $images = News_image::select('other_image', 'id')->where('news_id', $row2->id)->get();
        foreach ($images as $img) {
            $img->other_image = $img->other_image ?? '';
        }
        $row2->images = $images;

        $row2->read_time = ReadTimeService::estimate($row2->description ?? null);

        return $row2;
    }

    /**
     * Format an RSS feed item (set defaults for fields not applicable to external feeds).
     */
    public function formatRssFeedItem(object $row2): object
    {
        // this method used for formatting data
        // if (empty($row2->image)) {
        //     $row2->image = '';
        // }
        // if (!empty($row2->link)) {
        //     $row2->content_value = $row2->link;
        // }
        // $row2->total_like     = $row2->total_like ?? 0;
        // $row2->total_views    = $row2->total_views ?? 0;
        // $row2->total_comments = $row2->total_comments ?? 0;
        // $row2->is_bookmark    = $row2->is_bookmark ?? 0;
        // $row2->images         = $row2->images ?? [];

        return $row2;
    }
    public function resolveAuthorNewsResults(object $row, int $languageId, int $offset, int $limit): array
    {
        $query = DB::table('tbl_news')
            ->select(
                'tbl_news.*',
                'tbl_category.category_name',
                DB::raw('IFNULL(tbl_subcategory.subcategory_name, "") AS subcategory_name'),
                DB::raw('IFNULL(tbl_news_view.viewcount, 0) AS total_views'),
                DB::raw('IFNULL(tbl_news_like.likecount, 0) AS total_like'),
            )
            ->where('tbl_news.is_draft', 0)
            ->where('tbl_news.status', 1)
            ->where('tbl_news.language_id', $languageId)
            ->leftJoin('tbl_subcategory', 'tbl_news.subcategory_id', '=', 'tbl_subcategory.id')
            ->leftJoin('tbl_location', 'tbl_news.location_id', '=', 'tbl_location.id')
            ->leftJoin(
                DB::raw('(SELECT news_id, COUNT(*) AS viewcount FROM tbl_news_view GROUP BY news_id) AS tbl_news_view'),
                fn($join) => $join->on('tbl_news.id', '=', 'tbl_news_view.news_id')
            )
            ->leftJoin(
                DB::raw('(SELECT news_id, COUNT(*) AS likecount FROM tbl_news_like WHERE status="1" GROUP BY news_id) AS tbl_news_like'),
                fn($join) => $join->on('tbl_news.id', '=', 'tbl_news_like.news_id')
            )
            ->leftJoin('tbl_category', 'tbl_news.category_id', '=', 'tbl_category.id');

        if ($row->user_ids) {
            $query->whereIn('tbl_news.user_id', explode(',', $row->user_ids));
        }
        return $this->paginate($query, $offset, $limit, 'tbl_news.id');
    }
}
