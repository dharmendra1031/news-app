<?php

namespace App\Services;

use App\Models\FeaturedSectionRssFeed;
use App\Models\FeaturedSections;
use Illuminate\Http\UploadedFile;

class FeaturedSectionCrudService
{
    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /**
     * Split category_ids array (format: "cat-X" | "subcat-X") into
     * two comma-separated strings.
     *
     * @param  array|null $ids
     * @return array{cat: string, subcat: string}
     */
    private function parseCategoryIds(?array $ids): array
    {
        $cat    = [];
        $subcat = [];

        foreach ($ids ?? [] as $id) {
            [$prefix, $value] = explode('-', $id, 2);
            if ($prefix === 'cat') {
                $cat[] = $value;
            } elseif ($prefix === 'subcat') {
                $subcat[] = $value;
            }
        }

        return [
            'cat'    => $cat    ? implode(',', $cat)    : '',
            'subcat' => $subcat ? implode(',', $subcat) : '',
        ];
    }

    /**
     * Implode an array into a comma-separated string, or return ''.
     *
     * @param  array|null $items
     */
    private function parseCommaList(?array $items): string
    {
        return !empty($items) ? implode(',', $items) : '';
    }

    /**
     * Decode meta_keyword JSON and return the formatted string.
     *
     * @param  string|null $rawJson
     */
    private function parseMetaKeyword(?string $rawJson): string
    {
        $decoded = json_decode($rawJson, true);
        return $decoded ? get_meta_keyword($decoded) : '';
    }

    /**
     * Assign all shared fields to the FeaturedSections model from the
     * incoming request data array.
     *
     * @param  FeaturedSections $section
     * @param  array            $data  Validated / merged request data
     * @param  string           $categoryIds  Pre-resolved category comma-list
     * @param  string           $subcategoryIds  Pre-resolved subcategory comma-list
     * @param  string           $newsId  Pre-resolved news comma-list
     * @param  string           $userIds  Pre-resolved user comma-list
     * @param  bool             $basedOnUserChoice
     */
    private function fillSectionFields(
        FeaturedSections $section,
        array $data,
        string $categoryIds,
        string $subcategoryIds,
        string $newsId,
        string $userIds,
        bool $basedOnUserChoice
    ): void {
        $section->language_id      = $data['language_id'] ?? $section->language_id ?? 0;
        $section->title            = $data['title'];
        $section->news_type        = $data['news_type'] ?? '';
        $section->videos_type      = $data['videos_type'] ?? '';
        $section->filter_type      = $data['filter_type'] ?? '';
        $section->subcategory_ids  = $subcategoryIds;
        $section->news_ids         = $newsId;
        $section->style_app        = $data['style_app'];
        $section->style_web        = $data['style_web'];
        $section->is_based_on_user_choice = $basedOnUserChoice ? 1 : 0;
        $section->user_ids         = $userIds ?: null;

        // Assign category_ids based on news_type
        if (($data['news_type'] ?? '') === 'rss_feeds_news') {
            $section->category_ids = $data['_category_list'] ?? '';
            // Clear filter_type when using RSS feeds
            $section->filter_type = '';
        } else {
            $section->category_ids = $categoryIds;
        }

        // When based-on-user-choice is enabled, clear news-specific fields
        if ($basedOnUserChoice) {
            $section->news_ids    = '';
            $section->news_type   = '';
            $section->videos_type = '';
            $section->filter_type = '';
            $section->category_ids = '';

        }

        // SEO fields
        $section->schema_markup     = $data['schema_markup'] ?? '';
        $section->meta_title        = $data['meta_title'] ?? '';
        $section->meta_description  = $data['meta_description'] ?? '';
        $section->meta_keyword      = $this->parseMetaKeyword($data['meta_keyword'] ?? null);
    }

    /**
     * Sync FeaturedSectionRssFeed rows for a given featured section.
     * On create, pass $existingIds = null to skip the delete step.
     *
     * @param  int        $featuredSectionId
     * @param  array      $rssFeedIds
     * @param  array|null $existingIds  rss_feed_id values to keep; others are deleted
     */
    private function syncRssFeeds(int $featuredSectionId, array $rssFeedIds, ?array $existingIds = null): void
    {
        // Strip any null / empty values sent by an unselected Select2 field
        $rssFeedIds = array_filter($rssFeedIds, fn($id) => !is_null($id) && $id !== '');

        if ($existingIds !== null) {
            // Remove feeds that are no longer selected (includes deleting all when $rssFeedIds is empty)
            FeaturedSectionRssFeed::where('featured_section_id', $featuredSectionId)
                ->whereNotIn('rss_feed_id', $rssFeedIds)
                ->delete();
        }

        if (empty($rssFeedIds)) {
            return;
        }   

        foreach ($rssFeedIds as $rssFeedId) {
            FeaturedSectionRssFeed::updateOrCreate(
                ['featured_section_id' => $featuredSectionId, 'rss_feed_id' => $rssFeedId],
                ['featured_section_id' => $featuredSectionId, 'rss_feed_id' => $rssFeedId]
            );
        }
    }

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    /**
     * Create a new FeaturedSections record.
     *
     * @param  array              $data  All request input
     * @param  UploadedFile|null  $file  Optional OG image
     * @param  string             $slug  Already-unique slug
     * @return array{error: bool, message: string}
     */
    public function store(array $data, ?UploadedFile $file, string $slug): array
    {
        ['cat' => $categoryIds, 'subcat' => $subcategoryIds] = $this->parseCategoryIds($data['category_ids'] ?? null);

        $newsId       = $this->parseCommaList($data['news_ids'] ?? null);
        $userIds      = $this->parseCommaList($data['author_news_type'] ?? null);
        $categoryList = $this->parseCommaList($data['category_list'] ?? null);

        // Make category_list accessible inside fillSectionFields
        $data['_category_list'] = $categoryList;

        $basedOnUserChoice = (bool) ($data['based_on_user_choice_mode'] ?? false);

        $section          = new FeaturedSections();
        $section->status  = 1;
        $section->slug    = $slug;

        $this->fillSectionFields($section, $data, $categoryIds, $subcategoryIds, $newsId, $userIds, $basedOnUserChoice);

        $section->og_image = $file
            ? compressAndUpload($file, 'feature_section_og_image')
            : '';

        $section->save();

        // Sync RSS feeds
        if (!empty($data['rss_feeds_news_type'])) {
            $this->syncRssFeeds($section->id, $data['rss_feeds_news_type']);
        }

        return ['error' => false, 'message' => __('created_success')];
    }

    /**
     * Update an existing FeaturedSections record.
     *
     * @param  array              $data            All request input
     * @param  UploadedFile|null  $file            Optional OG image replacement
     * @param  FeaturedSections   $section         The model to update
     * @param  string             $slug            Already-validated unique slug
     * @param  int                $status          1 = active, 0 = inactive
     * @return array{error: bool, message: string}
     */
    public function update(array $data, ?UploadedFile $file, FeaturedSections $section, string $slug, int $status): array
    {
        ['cat' => $categoryIds, 'subcat' => $subcategoryIds] = $this->parseCategoryIds($data['category_ids'] ?? null);

        $newsId       = $this->parseCommaList($data['news_ids'] ?? null);
        $userIds      = $this->parseCommaList($data['author_news_type'] ?? null);
        $categoryList = $this->parseCommaList($data['category_list'] ?? null);

        $data['_category_list'] = $categoryList;

        $basedOnUserChoice = (bool) ($data['edit_based_on_user_choice_mode'] ?? false);

        $section->slug   = generateUniqueSlug($slug);
        $section->status = $status;

        $this->fillSectionFields($section, $data, $categoryIds, $subcategoryIds, $newsId, $userIds, $basedOnUserChoice);

        if ($file) {
            $section->og_image = compressAndReplace($file, 'feature_section_og_image', $section->getRawOriginal('og_image'));
        }

        $section->save();

        if (($data['news_type'] ?? '') !== 'rss_feeds_news') {
            FeaturedSectionRssFeed::where('featured_section_id', $section->id)->delete();
        } else {
            $this->syncRssFeeds(
                $section->id,
                $data['rss_feeds_news_type'] ?? [],
                []
            );
        }
        return ['error' => false, 'message' => __('updated_success')];
    }
}
