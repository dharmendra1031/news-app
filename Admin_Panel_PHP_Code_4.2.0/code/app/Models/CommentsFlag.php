<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CommentsFlag extends Model
{
    use HasFactory;

    protected $table = 'tbl_comment_flag';

    protected $fillable = ['comment_id', 'user_id', 'news_id', 'message', 'status', 'date'];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function news()
    {
        return $this->belongsTo(News::class, 'news_id');
    }

    public function comment()
    {
        return $this->belongsTo(Comments::class, 'comment_id');
    }
}
