<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RSS extends Model
{
    use HasFactory;

    protected $table = 'tbl_rss';

    protected $fillable = ['language_id', 'category_id', 'subcategory_id', 'tag_id',  'feed_name', 'feed_url', 'status', 'last_fetched_at'];

    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    public function tag()
    {
        return $this->belongsTo(Tag::class, 'tag_id', 'id');
    }

    public function sub_category()
    {
        return $this->belongsTo(SubCategory::class, 'subcategory_id');
    }

    public function featured_section_rss_feeds()
    {
        return $this->hasMany(FeaturedSectionRssFeed::class, 'featured_section_rss_feeds', 'rss_feed_id', 'featured_section_id');
    }

    public function feedItem()
    {
        return $this->hasMany(FeedItem::class, 'rss_source_id');
    }
}
