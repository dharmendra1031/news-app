<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasSafeOrder;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class PodcastEpisodes extends Model
{
    use HasFactory, HasSafeOrder;

    protected $table = 'podcast_episodes';

    protected $orderable = ['id', 'episode_no', 'title', 'slug', 'published_at', 'duration_seconds'];

    protected $fillable = ['podcast_id','episode_no','title', 'slug', 'description','status','image','source_type','audio_url','duration_seconds','draft','published_at'];


    protected $appends = ['listening_history', 'is_bookmarked'];

    protected $hidden = [ 'updated_at','created_at',];

    protected $casts = [
        'draft' => 'boolean',
        'duration_seconds' => 'integer',
    ];

    protected function getImageAttribute($value)
    {
        if ($value) {
            $value = str_starts_with($value, 'storage/') ? substr($value, strlen('storage/')) : $value;

            return url(Storage::disk('public')->url($value));
        }

        return $value;
    }

    protected function getAudioUrlAttribute($value)
    {
        if ($value && $this->source_type !== 'youtube_link' && !filter_var($value, FILTER_VALIDATE_URL)) {
            $value = str_starts_with($value, 'storage/') ? substr($value, strlen('storage/')) : $value;

            return url(Storage::disk('public')->url($value));
        }

        return $value;
    }

    protected function getListeningHistoryAttribute()
    {
        if ($this->relationLoaded('playHistory')) {
            return $this->getRelation('playHistory')->first();
        }

        return Auth::user()
            ? $this->playHistory()->where('user_id', Auth::id())->first()
            : null;
    }

    protected function getIsBookmarkedAttribute()
    {
        if ($this->relationLoaded('bookmarks')) {
            return $this->getRelation('bookmarks')->isNotEmpty();
        }

        return Auth::user()
            ? $this->bookmarks()->where('user_id', Auth::id())->exists()
            : false;
    }

    public function scopeSearch($query, $search)
    {
        return $query->where(function ($q) use ($search) {
            $q->where('title', 'like', '%' . $search . '%')
                ->orWhere('description', 'like', '%' . $search . '%');
        });
    }

    public function podcast()
    {
        return $this->belongsTo(Podcasts::class, 'podcast_id');
    }
    public function playHistory()
    {
        return $this->hasMany(EpisodePlayHistory::class, 'episode_id');
    }
    public function bookmarks()
    {
        return $this->hasMany(EpisodeBookmarks::class, 'episode_id');
    }
}
