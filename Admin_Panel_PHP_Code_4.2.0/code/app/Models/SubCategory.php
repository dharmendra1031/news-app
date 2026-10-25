<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class SubCategory extends Model
{
    use HasFactory;

    protected $table = 'tbl_subcategory';

    protected $fillable = ['category_id', 'subcategory_name', 'image', 'language_id', 'slug', 'row_order'];

    public function getImageAttribute($image)
    {
        return $image && Storage::disk('public')->exists($image) ? url(Storage::url('/' . $image)) : '';
    }

    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    public function news()
    {
        return $this->hasMany(News::class, 'subcategory_id');
    }

    public function notification()
    {
        return $this->hasMany(SendNotification::class, 'subcategory_id');
    }

    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($subcategory) {
            $subcategory->notification()->each(function ($notification) {
                if (!is_null($notification->image) && Storage::disk('public')->exists($notification->getRawOriginal('image'))) {
                    Storage::disk('public')->delete($notification->getRawOriginal('image'));
                }
            });
            $subcategory->notification()->delete();
            $subcategory->news()->each(function ($news) {
                if (!is_null($news->image) && Storage::disk('public')->exists($news->getRawOriginal('image'))) {
                    Storage::disk('public')->delete($news->getRawOriginal('image'));
                }
                $newsDirectory = 'news/' . $news->id;
                if (Storage::disk('public')->exists($newsDirectory)) {
                    Storage::disk('public')->deleteDirectory($newsDirectory);
                }
                $news->images()->each(function ($subnews) {
                    $filePath2 = $subnews->getRawOriginal('other_image');
                    if (!is_null($subnews->other_image) && Storage::disk('public')->exists($filePath2)) {
                        Storage::disk('public')->delete($filePath2);
                    }
                });
                $news->images()->delete();
                $news->newslike()->delete();
                $news->newsview()->delete();
                $news->comments()->each(function ($comment) {
                    $comment->comment_flag()->delete();
                    $comment->comment_like()->delete();
                    $comment->comment_notification()->delete();
                });
                $news->comments()->delete();
                $news->bookmark()->delete();
            });
        });
    }
}
