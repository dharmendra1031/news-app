<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $table = 'tbl_users';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'firebase_id',
        'name',
        'slug',
        'type',
        'email',
        'mobile',
        'profile',
        'fcm_id',
        'status',
        'date',
        'is_author'
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = ['password', 'remember_token', 'updated_at', 'created_at'];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    /**
     * Generate and persist a unique slug for this user, if it doesn't already have one.
     * Called when an author request is made/approved, so lookups by slug are stable
     * (unlike a computed accessor, which can't be reversed back to a user).
     */
    public function ensureSlug(): void
    {
        if (!empty($this->slug)) {
            return;
        }

        $base = Str::slug($this->name) ?: Str::random(8);
        $slug = $base;
        $i = 1;

        while (self::where('slug', $slug)->where('id', '!=', $this->id)->exists()) {
            $slug = $base . '-' . $i++;
        }

        $this->slug = $slug;
        $this->save();
    }

    public function getProfileAttribute($profile)
    {
        if ($this->type == 'email' || $this->type == 'mobile' || $this->type == 'fb') {
            if (!empty($profile) && strpos($profile, 'profile/') === false) {
                $profile = 'profile/' . $profile;
            }
            return $profile && Storage::disk('public')->exists($profile) ? url(Storage::url('/' . $profile)) : '';
        } else {
            if (stripos($profile, 'google') !== false) {
                return $profile;
            } elseif (stripos($profile, 'facebook') !== false) {
                return $profile;
            } else {
                if (!empty($profile) && strpos($profile, 'profile/') === false) {
                    $profile = 'profile/' . $profile;
                }
                return $profile && Storage::disk('public')->exists($profile) ? url(Storage::url('/' . $profile)) : '';
            }
        }
    }


    // scope for search
    public function scopeSearch($query, $search)
    {
        if ($search != '') {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                    ->orWhere('email', 'LIKE', "%{$search}%")
                    ->orWhere('mobile', 'LIKE', "%{$search}%");
            });
        }
    }

    public function roles()
    {
        return $this->belongsTo(Role::class, 'role');
    }

    public function user_category()
    {
        return $this->hasOne(UserCategory::class, 'user_id');
    }
    public function news(){
        return $this->hasMany(News::class, 'user_id', 'id');
    }

    public function author()
    {
        return $this->hasOne(Author::class, 'user_id', 'id');
    }

    // public function author_news()
    // {
    //     return $this->hasMany(News::class, 'user_id', 'id')->where('is_draft', 0);
    // }
    public function follow()
    {
        return $this->hasMany(PodcastFollow::class);
    }
    public function bookmark()
    {
        return $this->hasMany(EpisodeBookmarks::class);
    }
    public function history()
    {
        return $this->hasMany(EpisodePlayHistory::class);
    }
    public function notificationPreferences()
    {
        return $this->hasMany(NotificationPreference::class);
    }
}
