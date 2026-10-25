<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Language extends Model
{
    use HasFactory;

    protected $table = 'tbl_languages';

    protected $fillable = ['language', 'code', 'status', 'isRTL', 'image', 'display_name', 'app_file', 'web_file', 'panel_file'];

    protected $hidden = ['created_at', 'updated_at'];

    public function getImageAttribute($image)
    {
        if (!empty($image) && strpos($image, 'flags/') === false) {
            $image = 'flags/' . $image;
        }

        return $image && Storage::disk('public')->exists($image) ? url(Storage::url($image)) : '';
    }

    public function ads_space()
    {
        return $this->hasMany(AdSpaces::class, 'language_id');
    }

    public function breaking_news()
    {
        return $this->hasMany(BreakingNews::class, 'language_id');
    }

    public function category()
    {
        return $this->hasMany(Category::class, 'language_id');
    }

    public function feature_section()
    {
        return $this->hasMany(FeaturedSections::class, 'language_id');
    }

    public function live_streaming()
    {
        return $this->hasMany(LiveStreaming::class, 'language_id');
    }

    public function page()
    {
        return $this->hasMany(Pages::class, 'language_id');
    }

    public function survey_question()
    {
        return $this->hasMany(SurveyQuestion::class, 'language_id');
    }

    public function tags()
    {
        return $this->hasMany(Tag::class, 'language_id');
    }

    public function token()
    {
        return $this->hasMany(Token::class, 'language_id');
    }

    public function e_news()
    {
        return $this->hasMany(Enews::class, 'language_id');
    }

    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($language) {
            $language->ads_space()->each(function ($ads_space) {
                if (!is_null($ads_space->ad_image) && Storage::disk('public')->exists($ads_space->getRawOriginal('ad_image'))) {
                    Storage::disk('public')->delete($ads_space->getRawOriginal('ad_image'));
                }
                if (!is_null($ads_space->web_ad_image) && Storage::disk('public')->exists($ads_space->getRawOriginal('web_ad_image'))) {
                    Storage::disk('public')->delete($ads_space->getRawOriginal('web_ad_image'));
                }
            });
            $language->ads_space()->delete();

            $language->breaking_news()->each(function ($breaking_news) {
                if (!is_null($breaking_news->image) && Storage::disk('public')->exists($breaking_news->getRawOriginal('image'))) {
                    Storage::disk('public')->delete($breaking_news->getRawOriginal('image'));
                }
                if (!is_null($breaking_news->content_value) && Storage::disk('public')->exists($breaking_news->getRawOriginal('content_value'))) {
                    Storage::disk('public')->delete($breaking_news->getRawOriginal('content_value'));
                }
                $breaking_news->breaking_news_view()->delete();
            });
            $language->breaking_news()->delete();

            $language->category()->each(function ($category) {
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
                    $news->comments()->delete();
                    $news->bookmark()->delete();
                });
                $category->news()->delete();
            });
            $language->category()->delete();

            $language->feature_section()->delete();

            $language->live_streaming()->each(function ($live_streaming) {
                if (!is_null($live_streaming->image) && Storage::disk('public')->exists($live_streaming->getRawOriginal('image'))) {
                    Storage::disk('public')->delete($live_streaming->getRawOriginal('image'));
                }
            });
            $language->live_streaming()->delete();

            $language->page()->each(function ($pages) {
                if (!is_null($pages->page_icon) && Storage::disk('public')->exists($pages->getRawOriginal('page_icon'))) {
                    Storage::disk('public')->delete($pages->getRawOriginal('page_icon'));
                }
                if (!is_null($pages->og_image) && Storage::disk('public')->exists($pages->getRawOriginal('og_image'))) {
                    Storage::disk('public')->delete($pages->getRawOriginal('og_image'));
                }
            });
            $language->page()->delete();

            $language->survey_question()->each(function ($survey) {
                $survey->SurveyOptions()->delete();
                $survey->surveyResult()->delete();
            });
            $language->survey_question()->delete();

            $language->tags()->each(function ($tag) {
                if (!is_null($tag->og_image) && Storage::disk('public')->exists($tag->getRawOriginal('og_image'))) {
                    Storage::disk('public')->delete($tag->getRawOriginal('og_image'));
                }
            });
            $language->tags()->delete();

            $language->token()->delete();
        });
    }
}
