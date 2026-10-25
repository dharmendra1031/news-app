<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BreakingNewsView extends Model
{
    use HasFactory;

    protected $table = 'tbl_breaking_news_view';

    protected $fillable = ['user_id', 'breaking_news_id'];
}
