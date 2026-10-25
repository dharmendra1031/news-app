<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\VideoShortComment;
use App\Models\VideoShortLike;
use Illuminate\Support\Facades\Storage;

class VideoShort extends Model
{
    use HasFactory;

    protected $table = 'video_shorts';

    protected $fillable = [
        'language_id',
        'category_id',
        'title',
        'slug',
        'video_type',
        'video_url',
        'description',
        'published_date',
        'status',
        'views_count',
        'shares_count'
    ];

    protected $casts = [
        'published_at' => 'datetime',
        'status' => 'boolean',
    ];

    protected $hidden = ['created_at', 'updated_at'];

    protected function getVideoUrlAttribute($value)
    {
        if ($this->video_type === 'youtubelink') {
        return $value;
        }
        if ($value) {
            return url(Storage::disk('public')->url($value));
        }

        return $value;
    }
    public function likes()
    {
        return $this->hasMany(VideoShortLike::class, 'video_shorts_id');
    }

    public function comments()
    {
        return $this->hasMany(VideoShortComment::class, 'video_shorts_id');
    }
    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }
}
