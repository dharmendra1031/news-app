<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class News_like extends Model
{
    use HasFactory;

    protected $table = 'tbl_news_like';

    protected $fillable = ['user_id', 'news_id', 'status'];

    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    public function news()
    {
        return $this->belongsTo(News::class, 'news_id');
    }
}
