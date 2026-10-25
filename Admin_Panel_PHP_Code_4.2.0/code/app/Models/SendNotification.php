<?php

namespace App\Models;

use App\Traits\HasSafeOrder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class SendNotification extends Model
{
    use HasFactory, HasSafeOrder;

    protected $table = 'tbl_notifications';

    protected $fillable = ['language_id', 'location_id', 'type', 'category_id', 'subcategory_id', 'news_id', 'title', 'message', 'image', 'category_preference', 'date_sent'];

    public function getImageAttribute($image)
    {
        if (!empty($image) && strpos($image, 'notification/') === false) {
            $image = 'notification/' . $image;
        }

        return $image && Storage::disk('public')->exists($image) ? url(Storage::url('/' . $image)) : '';
    }

    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    public function sub_category()
    {
        return $this->belongsTo(SubCategory::class, 'subcategory_id');
    }

    public function news()
    {
        return $this->belongsTo(News::class, 'news_id');
    }

    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($image) {
            // before delete() method call this
            if (!is_null($image->image) && Storage::disk('public')->exists($image->getRawOriginal('image'))) {
                Storage::disk('public')->delete($image->getRawOriginal('image'));
            }
        });
    }
}
