<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bookmark;
use App\Models\News_like;
use App\Models\News_view;
use App\Models\Settings;
use App\Models\Tag;
use App\Traits\ResolvesLanguage;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

abstract class BaseApiController extends Controller
{
    use ResolvesLanguage;

    protected string $toDate;
    protected string $toDateTime;
    protected mixed $nearest_location_measure;

    public function __construct()
    {
        $nearest_location_measure = Settings::where('type', 'nearest_location_measure')->first();
        $this->nearest_location_measure = $nearest_location_measure->message ?? 1000;
        $this->toDate     = date('Y-m-d');
        $this->toDateTime = date('Y-m-d H:i:s');
    }

    /**
     * Enrich a news row with like, bookmark, view counts, tags and expiry flag.
     */
    protected function getNewsData($row, $news_id)
    {
        $user_id   = Auth::check() ? Auth::user()->id : 0;
        $news_like = News_like::where('news_id', $news_id);

        $row->like        = $news_like->clone()->where('status', 1)->where('user_id', $user_id)->count('id');
        $row->total_like  = $news_like->clone()->where('status', 1)->count('id');

        $news_bookmark       = Bookmark::where('news_id', $news_id);
        $row->total_bookmark = $news_bookmark->clone()->count('id');
        $row->bookmark       = $news_bookmark->clone()->where('user_id', $user_id)->count('id');
        $row->total_views    = News_view::where('news_id', $news_id)->count('id');

        $row->tag_name = '';
        $row->tag      = [];
        if (isset($row->tag_id) && $row->tag_id != '') {
            $row->tag_name = Tag::whereIn('id', explode(',', $row->tag_id))->distinct()->pluck('tag_name')->implode(',');
            $row->tag      = Tag::select('id', 'tag_name', 'slug')->whereIn('id', explode(',', $row->tag_id))->get();
        }

        $row->is_expired = 0;
        if ($row->show_till && $row->show_till != '0000-00-00') {
            $row->is_expired = date('Y-m-d') > $row->show_till ? 1 : 0;
        }

        return $row;
    }

    /**
     * Generate a URL-safe slug from a title string.
     */
    protected function generateSlugFromTitle(string $title): string
    {
        $slug = strtolower($title);
        $slug = preg_replace('/[^a-z0-9-]/', '', str_replace(' ', '-', $slug));

        return empty($slug) ? 'video-' . time() : $slug;
    }

    /**
     * Normalize a news image path and return the full public URL.
     */
    protected function resolveNewsImageUrl(?string $image): string
    {
        if (empty($image)) {
            return '';
        }
        if (strpos($image, 'news/') === false) {
            $image = 'news/' . $image;
        }
        return Storage::disk('public')->exists($image) ? url(Storage::url($image)) : '';
    }

    /**
     * Normalize a news video content_value path and return the full public URL.
     */
    protected function resolveNewsVideoUrl(?string $contentValue): string
    {
        if (empty($contentValue)) {
            return '';
        }
        if (strpos($contentValue, 'news_video/') === false) {
            $contentValue = 'news_video/' . $contentValue;
        }
        return url(Storage::url('/' . $contentValue));
    }
}
