<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasSafeOrder;

class EpisodeBookmarks extends Model
{
    use HasFactory, HasSafeOrder;
    protected $table = 'episode_bookmarks';

    protected $orderable = ['id', 'followed_at', 'created_at'];

    protected $fillable = ['followed_at','episode_id','user_id'];

    protected $casts = [
        'followed_at' => 'datetime',
    ];

    public function episode()
    {
        return $this->belongsTo(PodcastEpisodes::class ,'episode_id');
    }
    public function user()
    {
        return $this->belongsTo(User::class ,'user_id');
    }
}
