<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class News_view extends Model
{
    use HasFactory;

    protected $table = 'tbl_news_view';

    protected $fillable = ['user_id', 'news_id'];
}
