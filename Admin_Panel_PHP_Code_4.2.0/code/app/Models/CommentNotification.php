<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CommentNotification extends Model
{
    use HasFactory;

    protected $table = 'tbl_comment_notification';

    protected $fillable = ['master_id', 'user_id', 'sender_id', 'type', 'message', 'date'];
}
