<?php

namespace App\Models;

use Egulias\EmailValidator\Parser\Comment;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class FeaturedSections extends Model
{
    use HasFactory;

    protected $table = 'tbl_featured_sections';

    protected $fillable = [
        'language_id', 'title',
        'news_type',
        'videos_type', 'filter_type',
        'category_ids', 'subcategory_ids',
        'news_ids', 'style_app',
        'style_web', 'row_order',
        'created_at', 'status',
        'is_based_on_user_choice', 'slug',
        'meta_keyword', 'schema_markup',
        'meta_description', 'meta_title',
        'og_image', 'user_ids'
    ];

    public function getOgImageAttribute($image)
    {
        return $image && Storage::disk('public')->exists($image) ? url(Storage::url('/' . $image)) : '';
    }

    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    public function location()
    {
        return $this->belongsTo(Location::class, 'location_id');
    }

    public function sub_category()
    {
        return $this->belongsTo(SubCategory::class, 'subcategory_id');
    }

    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    public function news()
    {
        return $this->hasMany(News::class);
    }

    public function comments()
    {
        return $this->hasMany(Comment::class, 'featured_section_id');
    }

    public function rss_feeds()
    {
        return $this->hasMany(FeaturedSectionRssFeed::class, 'featured_section_id');
    }
}
