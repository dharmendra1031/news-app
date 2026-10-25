<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Log;

class Comments extends Model
{
    use HasFactory;

    protected $table = 'tbl_comment';

    protected $fillable = ['parent_id', 'user_id', 'news_id', 'message', 'status', 'date'];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function news()
    {
        return $this->belongsTo(News::class, 'news_id');
    }

    public function comment_flag()
    {
        return $this->hasMany(CommentsFlag::class, 'comment_id');
    }

    public function comment_like()
    {
        return $this->hasMany(CommentsLike::class, 'comment_id');
    }

    public function comment_notification()
    {
        return $this->hasMany(CommentNotification::class, 'master_id');
    }

    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($comment) {
            $comment->comment_flag()->delete();
            $comment->comment_like()->delete();
            $comment->comment_notification()->delete();
        });
    }
}
