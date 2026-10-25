<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NotificationPreference extends Model
{
    use HasFactory;

    protected $table = 'notification_preferences';

    protected $fillable = ['user_id', 'notification_type_id', 'status'];

    protected $casts = [
        'status' => 'boolean',
    ];

    public function user(){
        return $this->belongsTo(User::class);
    }

    public function type(){
        return $this->belongsTo(NotificationType::class, 'notification_type_id');
    }
}
