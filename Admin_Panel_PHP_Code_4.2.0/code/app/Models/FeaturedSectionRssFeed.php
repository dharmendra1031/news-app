<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeaturedSectionRssFeed extends Model
{
    use HasFactory;

    protected $table = 'featured_section_rss_feeds';

    protected $fillable = ['featured_section_id', 'rss_feed_id'];

    protected $hidden = ['created_at', 'updated_at'];

    public function featured_section()
    {
        return $this->belongsTo(FeaturedSections::class, 'featured_section_id');
    }

    public function rss_feed()
    {
        return $this->belongsTo(RSS::class, 'rss_feed_id');
    }
}
