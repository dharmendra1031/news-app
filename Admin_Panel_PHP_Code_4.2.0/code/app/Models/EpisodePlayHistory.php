<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasSafeOrder;

class EpisodePlayHistory extends Model
{
    use HasFactory, HasSafeOrder;

    protected $table = 'episode_play_history';

    protected $orderable = ['id', 'created_at', 'listened_seconds', 'completed'];

    protected $fillable = ['id','episode_id','user_id','listened_seconds','completed'];


    protected $hidden = ['updated_at', 'created_at'];

    public function episode()
    {
        return $this->belongsTo(PodcastEpisodes::class ,'episode_id');
    }
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
