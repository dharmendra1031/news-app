<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class SocialMedia extends Model
{
    use HasFactory;

    protected $table = 'tbl_social_media';

    protected $fillable = ['id', 'image', 'link', 'row_order'];

    public function getImageAttribute($image)
    {
        if ($image && strpos($image, 'social_media/') === false) {
            $image = 'social_media/' . $image;
        }

        return $image && Storage::disk('public')->exists($image) ? url(Storage::url($image)) : '';
    }

    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($res) {
            if (!is_null($res->image) && Storage::disk('public')->exists($res->getRawOriginal('image'))) {
                Storage::disk('public')->delete($res->getRawOriginal('image'));
            }
        });
    }
}
