<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Traits\HasSafeOrder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Category extends Model
{
    use HasFactory, HasSafeOrder;

    protected $table = 'tbl_category';

    protected $fillable = ['id', 'language_id', 'category_name', 'slug', 'row_order', 'image', 'meta_title', 'meta_description', 'meta_keyword', 'schema_markup'];

    protected $orderable = ['id', 'category_name', 'slug', 'row_order'];

    public function getImageAttribute($image)
    {
        if ($image && strpos($image, 'category/') === false) {
            $image = 'category/' . $image;
        }

        return $image && Storage::disk('public')->exists($image) ? url(Storage::url($image)) : '';
    }

    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    public function sub_categories()
    {
        return $this->hasMany(SubCategory::class, 'category_id');
    }

    public function news()
    {
        return $this->hasMany(News::class, 'category_id');
    }

    public function notification()
    {
        return $this->hasMany(SendNotification::class, 'category_id');
    }

    public function user_category()
    {
        return $this->hasMany(UserCategory::class, 'category_id');
    }

    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($category) {
            if (!is_null($category->image) && Storage::disk('public')->exists($category->getRawOriginal('image'))) {
                Storage::disk('public')->delete($category->getRawOriginal('image'));
            }
            $category->user_category()->delete();
            $category->sub_categories()->delete();
            $category->notification()->each(function ($notification) {
                if (!is_null($notification->image) && Storage::disk('public')->exists($notification->getRawOriginal('image'))) {
                    Storage::disk('public')->delete($notification->getRawOriginal('image'));
                }
            });
            $category->notification()->delete();

            $category->news()->each(function ($news) {
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
            $category->news()->delete();
        });
    }
}
