<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Author extends Model
{
    use HasFactory;

    protected $table = 'tbl_authors';

    protected $fillable = [
        'user_id',
        'bio',
        'telegram_link',
        'linkedin_link',
        'facebook_link',
        'whatsapp_link',
        'status',
        'auto_approve'
    ];

    protected $hidden = [
        'updated_at',
        'created_at'
    ];


    // scope for search
    public function scopeSearch($query, $search)
    {
        return $query->where('bio', 'like', '%' . $search . '%')
        ->where('status', $search)
        ->orWhereHas('user', function($query) use ($search) {
            $query->where('name', 'like', '%' . $search . '%')
            ->orWhere('email', 'like', '%' . $search . '%');
        });
    }


    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function news()
    {
        return $this->hasMany(News::class, 'user_id', 'user_id');
    }
    public function podcast()
    {
        return $this->hasMany(Podcasts::class, 'user_id', 'user_id');
    }
}
