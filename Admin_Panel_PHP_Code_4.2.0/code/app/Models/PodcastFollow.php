<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PodcastFollow extends Model
{
    use HasFactory;
    
    protected $table = 'podcast_follows';

    public $timestamps = false;

    protected $fillable = ['podcast_id','user_id','followed_at'];

    protected $casts = [
        'followed_at' => 'datetime',
    ];

    public function podcast()
    {
       return $this->belongsTo(Podcasts::class,'podcast_id');
    }
    public function user()
    {
        return $this->belongsTo(User::class,'user_id');
    }
}
