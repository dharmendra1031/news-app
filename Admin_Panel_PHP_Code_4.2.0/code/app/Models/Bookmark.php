<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Bookmark extends Model
{
    use HasFactory;

    protected $table = 'tbl_bookmark';

    protected $fillable = ['user_id', 'news_id'];

    public function news()
    {
        return $this->belongsTo(News::class, 'news_id');
    }
}
