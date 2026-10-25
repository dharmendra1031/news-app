<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CommentsLike extends Model
{
    use HasFactory;

    protected $table = 'tbl_comment_like';

    protected $fillable = ['user_id', 'comment_id', 'status'];
}
