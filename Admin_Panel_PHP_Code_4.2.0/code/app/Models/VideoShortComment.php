<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VideoShortComment extends Model
{
    use HasFactory;

    protected $table = 'video_shorts_comments';

    protected $fillable = [
        'video_shorts_id',
        'user_id',
        'comment',
        'status',
    ];

    protected $casts = [
        'status' => 'boolean',
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
