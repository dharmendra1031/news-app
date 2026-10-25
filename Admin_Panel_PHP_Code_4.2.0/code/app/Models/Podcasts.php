<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasSafeOrder;
use Illuminate\Support\Facades\Storage;

class Podcasts extends Model
{
    use HasFactory, HasSafeOrder;

    protected $table = 'podcasts';

    protected $fillable = ['id','user_id','title','slug','description','image','draft','status','published_at','meta_title','meta_description','meta_keyword','schema_markup'];

    protected $appends = ['follower_count', 'episode_count'];

    protected $orderable = ['id','user_id'];

    protected $hidden = [ 'updated_at','created_at',];

    protected function getImageAttribute($value)
    {
        if ($value) {
            return url(Storage::disk('public')->url($value));
        }

        return $value;
    }

    protected function getFollowerCountAttribute()
    {
        $count = $this->follow()->count();

        return $this->formatNumber($count);
    }
    
    protected function getEpisodeCountAttribute()
    {
        $userId = auth()?->id();

        $query = $this->episodes();

        if ($userId != $this->user_id) {
            $query->where('status', 1)
                  ->where('draft', 0);
        }

        return $query->count();
    }
    
    private function formatNumber($number)
    {
        if ($number < 1000) {
            return (string) $number;
        }

        $units = ['', 'K', 'M', 'B', 'T'];
        $power = floor(log($number, 1000));

        $formatted = $number / pow(1000, $power);

        return rtrim(rtrim(number_format($formatted, 1), '0'), '.') . $units[$power];
    }

    // protected function getEpisodeCountAttribute()
    // {
    //     // where status = 1 and not drafted
    //     return $this->episodes()->where('status', 1)->where('draft', 0)->count();
    // }

        // scopes
    public function scopeSearch($query, $search)
    {
        return $query->when($search, function ($q) use ($search) {
            $q->where(function ($q2) use ($search) {
                $q2->where('title', 'like', "%{$search}%")
                   ->orWhere('slug', 'like', "%{$search}%")
                   ->orWhere('description', 'like', "%{$search}%");
            });
        });
    }



    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
    public function author()
    {
        return $this->belongsTo(Author::class, 'user_id', 'user_id');
    }
    public function episodes()
    {
        return $this->hasMany(PodcastEpisodes::class, 'podcast_id');
    }
    public function follow()
    {
        return $this->hasMany(PodcastFollow::class, 'podcast_id');
    }
    public function bookmark()
    {
        return $this->hasMany(EpisodeBookmarks::class);
    }
}
