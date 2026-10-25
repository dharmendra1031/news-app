<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VideoShortLike extends Model
{
    use HasFactory;
    protected $table = 'video_shorts_likes';

    protected $fillable = ['video_shorts_id', 'user_id', 'like', 'dislike'];
    protected $casts = [
        'like' => 'boolean',
        'dislike' => 'boolean',
    ];
    protected $hidden = ['created_at','updated_at'];

    public function videoShort()
    {
        return $this->belongsTo(VideoShort::class, 'video_shorts_id');
    }
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}