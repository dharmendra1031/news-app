<?php

namespace App\Models;

use App\Traits\HasSafeOrder;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class FeedItem extends Model
{
    use HasFactory, HasSafeOrder;

    protected $fillable = [
        'rss_source_id', 'guid', 'title', 'url',
        'description', 'image_url', 'author', 'published_at', 'fetched_at'
    ];


    protected $orderable = ['rss_source_id', 'id', 'title', 'published_at', 'fetched_at'];


    protected $casts = ['published_at' => 'datetime', 'fetched_at' => 'datetime'];

    protected $hidden = ['created_at', 'updated_at'];

    protected $appends = ['published_at_human'];

    // human readable published_at date
    // public function getPublishedAtHumanAttribute()
    // {
    //     return $this->published_at
    //         ? Carbon::parse($this->published_at)->diffForHumans()
    //         : null;
    // }
    public function getPublishedAtHumanAttribute()
    {
        if (!$this->published_at) {
            return null;
        }

        // published_at is stored as UTC; convert to the admin-configured app timezone for display
        $date = Carbon::parse($this->published_at, 'UTC')
                      ->setTimezone(config('app.timezone'));

        if ($date->diffInHours(now()) < 24) {
            return $date->diffForHumans();
        }
        return $date->diffForHumans() . ' (' . $date->format('d M Y, h:i A') . ')';
    }
    // scope
    // select only few columns
    public function scopeSelectedColumns($query)
    {
        return $query->select(
            'id', 'rss_source_id', 'title', 'url',
            'description', 'image_url', 'author', 'published_at',
            // DB::raw("DATE_FORMAT(published_at, '%d %b %Y, %h:%i %p') as published_at_human")
        );
    }


    public function source()
    {
        return $this->belongsTo(RSS::class, 'rss_source_id');
    }
}
