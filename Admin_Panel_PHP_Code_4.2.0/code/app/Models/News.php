<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use App\Traits\HasSafeOrder;

class News extends Model
{
    use HasFactory, HasSafeOrder;

    protected $table = 'tbl_news';

    protected $fillable = [
        'category_id',
        'subcategory_id',
        'tag_id',
        'title', 'date', 'published_date', 'description',
        'summarized_description','status', 'show_till',
        'language_id', 'location_id', 'meta_keyword',
        'meta_title', 'meta_description', 'slug', 'is_draft', 'is_short_news'
    ];

    protected $orderable = ['id', 'title', 'date', 'published_date', 'status', 'show_till', 'language_id', 'location_id', 'meta_keyword', 'meta_title', 'meta_description', 'slug', 'is_draft', 'is_short_news'];

    protected $appends = ['language_code'];

    // get from language_id column
    public function getLanguageCodeAttribute()
    {
        return $this->language?->code ?? '';
    }

    public function getImageAttribute($image)
    {
        if (!empty($image) && strpos($image, 'news/') === false) {
            $image = 'news/' . $image;
        }

        return $image && Storage::disk('public')->exists($image) ? url(Storage::url($image)) : null;
    }

    public function language()
    {
        return $this->belongsTo(Language::class, 'language_id');
    }

    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    public function tag()
    {
        return $this->belongsTo(Tag::class, 'tag_id');
    }

    // used to author drafted news : later apply for all query where need of tags
    public function tags()
    {
        return $this->belongsToMany(Tag::class, 'tag_id');
    }

    public function sub_category()
    {
        return $this->belongsTo(SubCategory::class, 'subcategory_id');
    }

    public function images()
    {
        return $this->hasMany(News_image::class);
    }

    public function location()
    {
        return $this->belongsTo(Location::class, 'location_id');
    }

    public function comments()
    {
        return $this->hasMany(Comments::class);
    }

    public function newsview()
    {
        return $this->hasMany(News_view::class);
    }

    public function newslike()
    {
        return $this->hasMany(News_like::class);
    }

    public function notification()
    {
        return $this->hasMany(SendNotification::class);
    }

    public function bookmark()
    {
        return $this->hasMany(Bookmark::class);
    }

    public function user(){
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    public function author(){
        return $this->belongsTo(Author::class, 'user_id', 'user_id');
    }

    protected static function booted()
    {
        parent::boot();

        static::deleting(function ($news) {
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
            $news->notification()->each(function ($notification) {
                if (!is_null($notification->image) && Storage::disk('public')->exists($notification->getRawOriginal('image'))) {
                    Storage::disk('public')->delete($notification->getRawOriginal('image'));
                }
            });
            $news->notification()->delete();
        });
    }

    // public function getTagIdAttribute()
    // {
    //     // dd($this->toArray());
    //     return collect(explode(',', rtrim($this->getAttribute('tag_id'), ',')))
    //         ->filter()
    //         ->values();
    // }
}
