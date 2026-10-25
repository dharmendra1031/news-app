import api from "./apiMiddleware";
import * as apiEndPoints from "./apiEndPoints";

// 1. Settings Api
export const getSettingsApi = async () => {
  try {
    const response = await api.post(apiEndPoints.GET_SETTINGS);

    if (response.status !== 200) {
      throw new Error("Failed to fetch settings");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching settings:", error);
    return null;
  }
};


// Gemini Api Key (requires a logged-in user's bearer token)
export const getGeminiApiKeyApi = async () => {
  try {
    const response = await api.post(apiEndPoints.GET_GEMINI_API_KEY);

    if (response.status !== 200) {
      throw new Error("Failed to fetch Gemini API key");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching Gemini API key:", error);
    return null;
  }
};


// 2. Categories Api
export const getCategoriesApi = async (params: { offset?: number; limit?: number; language_code: string; slug?: string }) => {
  try {
    const response = await api.post(apiEndPoints.GET_CATEGORIES, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch categories");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching categories:", error);
    return null;
  }
};


// Set User Categories Api
export const setUserCategoriesApi = async (params: { category_id: string }) => {
  try {
    const response = await api.post(apiEndPoints.SET_USER_CATEGORIES, params);

    if (response.status !== 200) {
      throw new Error("Failed to update category preferences");
    }

    return response?.data;
  } catch (error) {
    console.error("Error updating category preferences:", error);
    return null;
  }
};

// 3. Market Alerts Api
export const getMarketAlertsApi = async (params: { offset?: number; limit?: number } = {}) => {
  try {
    const response = await api.post(apiEndPoints.GET_MARKET_ALERTS, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch market alerts");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching market alerts:", error);
    return null;
  }
};

// 4. Podcasts Api
export const getPodcastsApi = async (params: { type?: string; offset?: number; limit?: number; slug?: string; search?: string } = {}) => {
  try {
    const response = await api.post(apiEndPoints.GET_PODCASTS, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch podcasts");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching podcasts:", error);
    return null;
  }
};

// Save Podcast Api — creates a podcast, or updates one when `id` is present.
export const savePodcastApi = async (params: {
  id?: number;
  title: string;
  slug: string;
  description: string;
  published_date?: string;
  draft?: 0 | 1;
  image?: File;
  meta_title?: string;
  meta_description?: string;
  meta_keyword?: string;
  schema_markup?: string;
}) => {
  try {
    const { id, title, slug, description, published_date, draft = 0, image, meta_title, meta_description, meta_keyword, schema_markup } = params;

    const formData = new FormData();
    formData.append("action_type", id ? "2" : "1");
    if (id) formData.append("id", String(id));
    formData.append("title", title);
    formData.append("slug", slug);
    formData.append("description", description);
    if (published_date) formData.append("published_date", published_date);
    formData.append("draft", String(draft));
    if (image) formData.append("image", image);
    if (meta_title) formData.append("meta_title", meta_title);
    if (meta_description) formData.append("meta_description", meta_description);
    if (meta_keyword) formData.append("meta_keyword", meta_keyword);
    if (schema_markup) formData.append("schema_markup", schema_markup);

    const response = await api.post(apiEndPoints.CREATE_PODCAST, formData);

    if (response.status !== 200) {
      throw new Error("Failed to save podcast");
    }

    return response?.data;
  } catch (error) {
    console.error("Error saving podcast:", error);
    return null;
  }
};

// Save Episode Api — creates an episode, or updates one when `episode_id` is present.
export const saveEpisodeApi = async (params: {
  episode_id?: number;
  podcast_id: number;
  title: string;
  slug: string;
  episode_no: number;
  description: string;
  published_date?: string;
  is_draft?: 0 | 1;
  source_type: string;
  audio_url?: string;
  audio_file?: File;
  image?: File;
}) => {
  try {
    const { episode_id, podcast_id, title, slug, episode_no, description, published_date, is_draft = 0, source_type, audio_url, audio_file, image } = params;

    const formData = new FormData();
    formData.append("action_type", episode_id ? "2" : "1");
    if (episode_id) formData.append("episode_id", String(episode_id));
    formData.append("podcast_id", String(podcast_id));
    formData.append("title", title);
    formData.append("slug", slug);
    formData.append("episode_no", String(episode_no));
    formData.append("description", description);
    if (published_date) formData.append("published_date", published_date);
    formData.append("is_draft", String(is_draft));
    formData.append("source_type", source_type);
    if (audio_url) formData.append("audio_url", audio_url);
    if (audio_file) formData.append("audio_file", audio_file);
    if (image) formData.append("image", image);

    const response = await api.post(apiEndPoints.CREATE_EPISODE, formData);

    if (response.status !== 200) {
      throw new Error("Failed to save episode");
    }

    return response?.data;
  } catch (error) {
    console.error("Error saving episode:", error);
    return null;
  }
};

// Get My Podcasts Api — the logged-in author's own podcasts, for manage-podcast.
export const getMyPodcastsApi = async (params: { type?: string; offset?: number; limit?: number; search?: string } = {}) => {
  try {
    const response = await api.post(apiEndPoints.GET_MY_PODCASTS, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch podcasts");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching my podcasts:", error);
    return null;
  }
};

// Delete Podcast Api
export const deletePodcastApi = async (params: { id: number }) => {
  try {
    const response = await api.post(apiEndPoints.DELETE_PODCAST, params);

    if (response.status !== 200) {
      throw new Error("Failed to delete podcast");
    }

    return response?.data;
  } catch (error) {
    console.error("Error deleting podcast:", error);
    return null;
  }
};

// 5. Ad Spaces Api   page: 'home_page' | 'news_details' | 'featured_section' | 'news_page'
export const getAdSpacesApi = async (params: { language_code: string; page: string; platform?: string }) => {
  try {
    const { platform = "web", ...rest } = params;
    const response = await api.post(apiEndPoints.GET_AD_SPACE_NEWS_DETAILS, { ...rest, platform });

    if (response.status !== 200) {
      throw new Error("Failed to fetch ad spaces");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching ad spaces:", error);
    return null;
  }
};


// 6. Live News Api
export const getLiveNewsApi = async (params: { language_code: string; offset?: number; limit?: number }) => {
  try {
    const response = await api.post(apiEndPoints.GET_LIVE_STREAMING, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch live news");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching live news:", error);
    return null;
  }
};

// 7. Breaking News Api
export const getBreaingNewsApi = async (params: { language_code: string; slug?: string; offset?: number; limit?: number }) => {
  try {
    const response = await api.post(apiEndPoints.GET_BREAKING_NEWS, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch breaking news");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching breaking news:", error);
    return null;
  }
};

// 8. Video News Api
export const getVideoNewsApi = async (params: {
  language_code: string;
  offset?: number;
  limit?: number;
  slug?: string;
  category_id?: number;
  category_slug?: string;
}) => {
  try {
    const response = await api.post(apiEndPoints.GET_VIDEO, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch video news");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching video news:", error);
    return null;
  }
};

// 9. Video Shorts (Reels) Api
export const getVideoShortsApi = async (params: { language_code: string; offset?: number; limit?: number; order?: "asc" | "desc" }) => {
  try {
    const { order = "desc", ...rest } = params;
    const response = await api.post(apiEndPoints.GET_VIDEO_SHORTS, { ...rest, order });

    if (response.status !== 200) {
      throw new Error("Failed to fetch video shorts");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching video shorts:", error);
    return null;
  }
};

// 10. RSS Feeds Api
export const getRssFeedItemsApi = async (params: {
  language_code: string;
  source_ids?: string;
  category_ids?: string;
  subcategory_ids?: string;
  page?: string | number;
  per_page?: string | number;
}) => {
  try {
    const { page = "1", ...rest } = params;
    const response = await api.post(apiEndPoints.GET_FEED_ITEMS, { ...rest, page });

    if (response.status !== 200) {
      throw new Error("Failed to fetch RSS feeds");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching RSS feeds:", error);
    return null;
  }
};

// 11. RSS Feed Sources Api
export const getRssFeedsApi = async (params: {
  language_code: string;
  offset?: number;
  limit?: number;
  category_id?: number;
  category_slug?: string;
  subcategory_id?: number;
  subcategory_slug?: string;
  tag_id?: number;
  tag_slug?: string;
  search?: string;
}) => {
  try {
    const response = await api.post(apiEndPoints.GET_RSS_FEED, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch RSS feed sources");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching RSS feed sources:", error);
    return null;
  }
};


// 12. More Pages Api
export const getMorePagesApi = async (params: { language_code: string; slug?: string; offset?: number; limit?: number }) => {
  try {
    const response = await api.post(apiEndPoints.GET_PAGES, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch pages");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching pages:", error);
    return null;
  }
};


// 13. Languages List Api
export const getLanguagesApi = async () => {
  try {
    const response = await api.post(apiEndPoints.GET_LANGUAGE_LIST);

    if (response.status !== 200) {
      throw new Error("Failed to fetch languages");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching languages:", error);
    return null;
  }
};

// 14. Language JSON Data Api
export const getLanguageJsonDataApi = async (params: { language_code: string; platform_type?: string }) => {
  try {
    const response = await api.post(apiEndPoints.GET_LANGUAGE_JSON_DATA, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch language json data");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching language json data:", error);
    return null;
  }
};


// 15. Tags Api
export const getTagsApi = async (params: { language_code: string; slug?: string; limit?: number; offset?: number }) => {
  try {
    const response = await api.post(apiEndPoints.GET_TAG, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch tags");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching tags:", error);
    return null;
  }
};

// Locations Api
export const getLocationApi = async (params: { limit?: number } = {}) => {
  try {
    const response = await api.post(apiEndPoints.GET_LOCATION, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch locations");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching locations:", error);
    return null;
  }
};

// Check Slug Availability Api
export const checkSlugAvailabilityApi = async (params: { slug: string }) => {
  try {
    const response = await api.post(apiEndPoints.CHECK_SLUG_AVAILABILITY, params);

    if (response.status !== 200) {
      throw new Error("Failed to check slug availability");
    }

    return response?.data;
  } catch (error) {
    console.error("Error checking slug availability:", error);
    return null;
  }
};

// Create Tag Api
export const createTagApi = async (params: { tag_name: string; language_code: string }) => {
  try {
    const formData = new FormData();
    formData.append("tag_name", params.tag_name);
    formData.append("language_code", params.language_code);

    const response = await api.post(apiEndPoints.CREATE_TAG, formData);

    if (response.status !== 200) {
      throw new Error("Failed to create tag");
    }

    return response?.data;
  } catch (error) {
    console.error("Error creating tag:", error);
    return null;
  }
};

// Set News Api — creates a news article (drafts included via is_draft).
export const setNewsApi = async (params: {
  /** Present only when updating an existing article. */
  id?: number;
  category_id: number;
  subcategory_id?: number;
  tag_id?: string;
  title: string;
  meta_title?: string;
  meta_description?: string;
  meta_keyword?: string;
  slug?: string;
  content_type?: string;
  content_data?: string;
  description?: string;
  summarized_description?: string;
  image?: File;
  otherImages?: File[];
  show_till?: string;
  language_code?: string;
  location_id?: number;
  published_date?: string | null;
  is_draft?: 0 | 1;
  is_short_news?: 0 | 1;
}) => {
  try {
    const {
      id,
      category_id,
      subcategory_id,
      tag_id,
      title,
      meta_title,
      meta_description,
      meta_keyword,
      slug,
      content_type,
      content_data,
      description,
      summarized_description,
      image,
      otherImages,
      show_till,
      language_code,
      location_id,
      published_date,
      is_draft = 0,
      is_short_news = 0,
    } = params;

    const formData = new FormData();
    if (id) {
      formData.append("action_type", "2");
      formData.append("news_id", String(id));
    } else {
      formData.append("action_type", "1");
    }
    formData.append("is_draft", String(is_draft));
    formData.append("title", title);
    formData.append("category_id", String(category_id));
    if (subcategory_id) formData.append("subcategory_id", String(subcategory_id));
    if (tag_id) formData.append("tag_id", tag_id);
    if (meta_title) formData.append("meta_title", meta_title);
    if (meta_description) formData.append("meta_description", meta_description);
    if (meta_keyword) formData.append("meta_keyword", meta_keyword);
    if (slug) formData.append("slug", slug);
    if (content_type) formData.append("content_type", content_type);
    if (content_data) formData.append("content_data", content_data);
    if (description) formData.append("description", description);
    if (summarized_description) formData.append("summarized_description", summarized_description);
    if (image) formData.append("image", image);
    otherImages?.forEach((file) => formData.append("ofile[]", file));
    if (show_till) formData.append("show_till", show_till);
    if (published_date) formData.append("published_date", published_date);
    if (language_code) formData.append("language_code", language_code);
    if (location_id) formData.append("location_id", String(location_id));
    formData.append("is_short_news", String(is_short_news));

    const response = await api.post(apiEndPoints.SET_NEWS, formData);

    if (response.status !== 200) {
      throw new Error("Failed to save news");
    }

    return response?.data;
  } catch (error) {
    console.error("Error saving news:", error);
    return null;
  }
};

// 16. Podcast Episodes Api
export const getEpisodeApi = async (params: {
  podcast_slug?: string;
  offset?: number;
  limit?: number;
  type?: string;
  is_author_check?: 0 | 1;
}) => {
  try {
    const response = await api.post(apiEndPoints.GET_EPISODE, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch episodes");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching episodes:", error);
    return null;
  }
};

// 17. My Episodes Api (history / bookmark — spans all podcasts, no podcast_slug)
export const getMyEpisodesApi = async (params: {
  offset?: number;
  limit?: number;
  type?: string;
}) => {
  try {
    const response = await api.post(apiEndPoints.MY_EPISODES, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch episodes");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching my episodes:", error);
    return null;
  }
};

// 17. Register Token Api
export const registertokenApi = async (params: {
  language_code?: string;
  token: string;
  latitude?: number;
  longitude?: number;
  user_id?: number;
}) => {
  try {
    const response = await api.post(apiEndPoints.REGISTER_TOKEN, params);

    if (response.status !== 200) {
      throw new Error("Failed to register token");
    }

    return response?.data;
  } catch (error) {
    console.error("Error registering token:", error);
    return null;
  }
};

// 18. Follow Podcast Api
export const followPodcastApi = async (params: { podcast_id: number; status: 0 | 1 }) => {
  try {
    const response = await api.post(apiEndPoints.FOLLOW_PODCAST, params);

    if (response.status !== 200) {
      throw new Error("Failed to follow podcast");
    }

    return response?.data;
  } catch (error) {
    console.error("Error following podcast:", error);
    return null;
  }
};

// 19. Bookmark Episode Api
export const bookmarkPodcastApi = async (params: { podcast_id: number; episode_id?: number; status: 0 | 1 }) => {
  try {
    const response = await api.post(apiEndPoints.BOOKMARK_EPISODE, params);

    if (response.status !== 200) {
      throw new Error("Failed to bookmark episode");
    }

    return response?.data;
  } catch (error) {
    console.error("Error bookmarking episode:", error);
    return null;
  }
};

// 20. Delete Episode Api
export const deleteEpisodeApi = async (params: { episode_id: number }) => {
  try {
    const response = await api.post(apiEndPoints.DELETE_EPISODE, params);

    if (response.status !== 200) {
      throw new Error("Failed to delete episode");
    }

    return response?.data;
  } catch (error) {
    console.error("Error deleting episode:", error);
    return null;
  }
};

// 21. Update Episode Listening Duration Api
export const updateEpisodeDurationApi = async (params: { episode_id: number; listened_seconds: number; completed?: boolean }) => {
  try {
    const response = await api.post(apiEndPoints.UPDATE_PLAY_DURATION, params);

    if (response.status !== 200) {
      throw new Error("Failed to update episode duration");
    }

    return response?.data;
  } catch (error) {
    console.error("Error updating episode duration:", error);
    return null;
  }
};

// 22. E-News Api
export const getENewsApi = async (params: { language_code: string; page?: string | number; per_page?: string | number }) => {
  try {
    const response = await api.post(apiEndPoints.E_NEWS, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch e-news");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching e-news:", error);
    return null;
  }
};

// 23. Video Short Like/Dislike Api
export const setVideoShortLikeDislikeApi = async (params: { video_shorts_id: number; action: "like" | "dislike" }) => {
  try {
    const response = await api.post(apiEndPoints.SET_VIDEO_LIKE_DISLIKE, params);

    if (response.status !== 200) {
      throw new Error("Failed to like/dislike video short");
    }

    return response?.data;
  } catch (error) {
    console.error("Error liking/disliking video short:", error);
    return null;
  }
};

// 24. Video Short View Api
export const setVideoShortViewApi = async (params: { video_shorts_id: number }) => {
  try {
    const response = await api.post(apiEndPoints.SET_VIDEO_SHORT_VIEW, params);

    if (response.status !== 200) {
      throw new Error("Failed to set video short view");
    }

    return response?.data;
  } catch (error) {
    console.error("Error setting video short view:", error);
    return null;
  }
};

// 25. Video Short Shares Api
export const setVideoShortSharesApi = async (params: { video_shorts_id: number }) => {
  try {
    const response = await api.post(apiEndPoints.SET_VIDEO_SHORT_SHARES, params);

    if (response.status !== 200) {
      throw new Error("Failed to set video short shares");
    }

    return response?.data;
  } catch (error) {
    console.error("Error setting video short shares:", error);
    return null;
  }
};

// 26. Get Video Short Comments Api
export const getVideoShortCommentApi = async (params: { video_shorts_id: number; offset?: number; limit?: number }) => {
  try {
    const response = await api.post(apiEndPoints.GET_VIDEO_SHORT_COMMENT, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch video short comments");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching video short comments:", error);
    return null;
  }
};

// 27. Set Video Short Comment Api
export const setVideoShortCommentApi = async (params: { video_shorts_id: number; comment: string }) => {
  try {
    const response = await api.post(apiEndPoints.SET_VIDEO_SHORT_COMMENT, params);

    if (response.status !== 200) {
      throw new Error("Failed to post video short comment");
    }

    return response?.data;
  } catch (error) {
    console.error("Error posting video short comment:", error);
    return null;
  }
};

// Get Notification Preferences Api
export const getNotificationPrefApi = async () => {
  try {
    const response = await api.post(apiEndPoints.GET_NOTIFICATION_PREF);

    if (response.status !== 200) {
      throw new Error("Failed to fetch notification preferences");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching notification preferences:", error);
    return null;
  }
};

// Set Notification Preferences Api
export const setNotificationPrefApi = async (params: { preferences: { notification_type_id: number; status: 0 | 1 }[] }) => {
  try {
    const response = await api.post(apiEndPoints.SEND_NOTIFICATION_PREF, params);

    if (response.status !== 200) {
      throw new Error("Failed to update notification preferences");
    }

    return response?.data;
  } catch (error) {
    console.error("Error updating notification preferences:", error);
    return null;
  }
};

// Get User By Id Api
export const getUserByIdApi = async () => {
  try {
    const response = await api.post(apiEndPoints.GET_USER_BY_ID);

    if (response.status !== 200) {
      throw new Error("Failed to fetch user details");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching user details:", error);
    return null;
  }
};

// User Signup Api
export const userSignUpApi = async (params: {
  id_token: string;
  firebase_id?: string;
  name?: string;
  email?: string;
  mobile?: string;
  type?: string;
  profile?: File;
  status?: string | number;
  fcm_id?: string;
}) => {
  try {
    const { id_token, firebase_id, name, email, mobile, type, profile, status, fcm_id } = params;
    const formData = new FormData();

    // Append only if the value is defined and not an empty string
    if (id_token) formData.append("id_token", id_token);
    if (firebase_id) formData.append("firebase_id", firebase_id);
    if (name) formData.append("name", name);
    if (email) formData.append("email", email);
    if (mobile) formData.append("mobile", mobile);
    if (type) formData.append("type", type);
    if (profile) formData.append("profile", profile);
    if (status) formData.append("status", String(status));
    if (fcm_id) formData.append("fcm_id", fcm_id);

    const response = await api.post(apiEndPoints.USER_SIGNUP, formData);

    if (response.status !== 200) {
      throw new Error("Failed to sign up user");
    }

    return response?.data;
  } catch (error) {
    console.error("Error signing up user:", error);
    return null;
  }
};

// Update Profile Api
export const updateProfileApi = async (params: {
  name?: string;
  email?: string;
  mobile?: string;
  profile?: File;
  bio?: string;
  telegram_link?: string;
  whatsapp_link?: string;
  facebook_link?: string;
  linkedin_link?: string;
}) => {
  try {
    const { name, email, mobile, profile, bio, telegram_link, whatsapp_link, facebook_link, linkedin_link } = params;
    const formData = new FormData();

    if (name !== undefined) formData.append("name", name);
    if (email !== undefined) formData.append("email", email);
    if (mobile !== undefined) formData.append("mobile", mobile);
    if (profile) formData.append("profile", profile);
    if (bio !== undefined) formData.append("bio", bio);
    if (telegram_link !== undefined) formData.append("telegram_link", telegram_link);
    if (whatsapp_link !== undefined) formData.append("whatsapp_link", whatsapp_link);
    if (facebook_link !== undefined) formData.append("facebook_link", facebook_link);
    if (linkedin_link !== undefined) formData.append("linkedin_link", linkedin_link);

    const response = await api.post(apiEndPoints.UPDATE_PROFILE, formData);

    if (response.status !== 200) {
      throw new Error("Failed to update profile");
    }

    return response?.data;
  } catch (error) {
    console.error("Error updating profile:", error);
    return null;
  }
};

// Become Author Api
export const becomeAuthorApi = async () => {
  try {
    const response = await api.post(apiEndPoints.BECOME_AUTHOR);

    if (response.status !== 200) {
      throw new Error("Failed to submit author request");
    }

    return response?.data;
  } catch (error) {
    console.error("Error submitting author request:", error);
    return null;
  }
};

// Get Author Profile And News Api
export const getAuthorDetailsApi = async (params: { user_slug: string; language_code: string; page?: string | number }) => {
  try {
    const response = await api.post(apiEndPoints.GET_AUTHOR_DETAILS, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch author details");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching author details:", error);
    return null;
  }
};

// Delete News Api
export const deleteNewsApi = async (params: { id: number }) => {
  try {
    const response = await api.post(apiEndPoints.DELETE_NEWS, params);

    if (response.status !== 200) {
      throw new Error("Failed to delete news");
    }

    return response?.data;
  } catch (error) {
    console.error("Error deleting news:", error);
    return null;
  }
};

// Delete a single "other image" already attached to a news article (edit flow).
export const deleteImagesApi = async (params: { id: number }) => {
  try {
    const response = await api.post(apiEndPoints.DELETE_IMAGES, params);

    if (response.status !== 200) {
      throw new Error("Failed to delete image");
    }

    return response?.data;
  } catch (error) {
    console.error("Error deleting image:", error);
    return null;
  }
};

// Get User Drafted News Api
export const getUserDraftedNewsApi = async (params: { author_id: number }) => {
  try {
    const response = await api.post(apiEndPoints.GET_USER_DRAFTED_NEWS, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch drafted news");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching drafted news:", error);
    return null;
  }
};

// Delete Account Api
export const deleteAccountApi = async () => {
  try {
    const response = await api.post(apiEndPoints.DELETE_ACCOUNT);

    if (response.status !== 200) {
      throw new Error("Failed to delete account");
    }

    return response?.data;
  } catch (error) {
    console.error("Error deleting account:", error);
    return null;
  }
};

export const getNewsApi = async (params: {
  language_code?: string;
  offset?: number;
  limit?: number;
  id?: number;
  get_user_news?: 0 | 1;
  search?: string;
  category_id?: number | string;
  category_slug?: string;
  subcategory_id?: number;
  subcategory_slug?: string;
  slug?: string;
  tag_id?: number | string;
  tag_slug?: string;
  latitude?: number | string | null;
  longitude?: number | string | null;
  merge_tag?: 0 | 1;
  last_n_days?: number | null;
  date?: string;
  year?: number | string;
}) => {
  try {
    const response = await api.post(apiEndPoints.GET_NEWS, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch news");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching news:", error);
    return null;
  }
};
// 28. Set News View Api
export const setNewsViewApi = async (params: { news_id: number }) => {
  try {
    const response = await api.post(apiEndPoints.SET_NEWS_VIEW, params);

    if (response.status !== 200) {
      throw new Error("Failed to set news view");
    }

    return response?.data;
  } catch (error) {
    console.error("Error setting news view:", error);
    return null;
  }
};

// 29. Set Breaking News View Api
export const setBreakingNewsViewApi = async (params: { breaking_news_id: number }) => {
  try {
    const response = await api.post(apiEndPoints.SET_BREAKING_NEWS_VIEW, params);

    if (response.status !== 200) {
      throw new Error("Failed to set breaking news view");
    }

    return response?.data;
  } catch (error) {
    console.error("Error setting breaking news view:", error);
    return null;
  }
};

// Get Bookmark Api
export const getBookmarkApi = async (params: { language_code: string; offset?: number; limit?: number }) => {
  try {
    const response = await api.post(apiEndPoints.GET_BOOKMARK, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch bookmarks");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching bookmarks:", error);
    return null;
  }
};

// 30. Set Bookmark Api
export const setBookmarkApi = async (params: { news_id: number; status: 0 | 1 }) => {
  try {
    const response = await api.post(apiEndPoints.SET_BOOKMARK, params);

    if (response.status !== 200) {
      throw new Error("Failed to bookmark news");
    }

    return response?.data;
  } catch (error) {
    console.error("Error bookmarking news:", error);
    return null;
  }
};

// 31. Set News Like/Dislike Api
export const setLikeDislikeApi = async (params: { news_id: number; status: 0 | 1 }) => {
  try {
    const response = await api.post(apiEndPoints.SET_LIKE_DISLIKE, params);

    if (response.status !== 200) {
      throw new Error("Failed to like/dislike news");
    }

    return response?.data;
  } catch (error) {
    console.error("Error liking/disliking news:", error);
    return null;
  }
};

// 32. Survey Questions Api
export const getSurveyQuestionsApi = async (params: { language_code: string }) => {
  try {
    const response = await api.post(apiEndPoints.GET_QUESTION, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch survey questions");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching survey questions:", error);
    return null;
  }
};

// 33. Survey Question Result Api
export const getSurveyResultApi = async (params: { language_code: string; question_id: number }) => {
  try {
    const response = await api.post(apiEndPoints.GET_QUESTION_RESULT, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch survey result");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching survey result:", error);
    return null;
  }
};

// 34. Submit Survey Answer Api
export const setSurveyResultApi = async (params: { language_code: string; question_id: number; option_id: number }) => {
  try {
    const response = await api.post(apiEndPoints.SET_QUESTION_RESULT, params);

    if (response.status !== 200) {
      throw new Error("Failed to submit survey answer");
    }

    return response?.data;
  } catch (error) {
    console.error("Error submitting survey answer:", error);
    return null;
  }
};

// 35. Get Comments Api
export const getCommentsByNewsApi = async (params: { news_id: number; offset?: number; limit?: number }) => {
  try {
    const response = await api.post(apiEndPoints.GET_COMMENT_BY_NEWS, params);

    if (response.status !== 200) {
      throw new Error("Failed to fetch comments");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching comments:", error);
    return null;
  }
};

// 36. Set Comment Api
export const setCommentApi = async (params: { language_code: string; parent_id?: number; news_id: number; message: string }) => {
  try {
    const response = await api.post(apiEndPoints.SET_COMMENT, params);

    if (response.status !== 200) {
      throw new Error("Failed to post comment");
    }

    return response?.data;
  } catch (error) {
    console.error("Error posting comment:", error);
    return null;
  }
};

// 37. Set Comment Like/Dislike Api
export const setCommentLikeDislikeApi = async (params: { language_code: string; comment_id: number; status: 0 | 1 | 2 }) => {
  try {
    const response = await api.post(apiEndPoints.SET_COMMENT_LIKE_DISLIKE, params);

    if (response.status !== 200) {
      throw new Error("Failed to like/dislike comment");
    }

    return response?.data;
  } catch (error) {
    console.error("Error liking/disliking comment:", error);
    return null;
  }
};

// 38. Delete Comment Api
export const deleteCommentApi = async (params: { comment_id: number }) => {
  try {
    const response = await api.post(apiEndPoints.DELETE_COMMENT, params);

    if (response.status !== 200) {
      throw new Error("Failed to delete comment");
    }

    return response?.data;
  } catch (error) {
    console.error("Error deleting comment:", error);
    return null;
  }
};

// 39. Report Comment (Flag) Api
export const setCommentFlagApi = async (params: { comment_id: number; news_id: number; message: string }) => {
  try {
    const response = await api.post(apiEndPoints.SET_FLAG, params);

    if (response.status !== 200) {
      throw new Error("Failed to report comment");
    }

    return response?.data;
  } catch (error) {
    console.error("Error reporting comment:", error);
    return null;
  }
};

// Featured Sections Api
// `offset`/`limit` page the news *inside* each section; `section_offset`/`section_limit`
// page the sections themselves.
export const getFeatureSectionsApi = async (params: {
  language_code: string;
  offset?: number;
  limit?: number;
  section_offset?: number;
  section_limit?: number;
  slug?: string;
  section_id?: number;
  latitude?: number | string;
  longitude?: number | string;
  isToken?: boolean;
  platform?: string;
}) => {
  try {
    const { platform = "web", ...rest } = params;
    const response = await api.post(apiEndPoints.GET_FEATURE_SECTION, { ...rest, platform });

    if (response.status !== 200) {
      throw new Error("Failed to fetch featured sections");
    }

    return response?.data;
  } catch (error) {
    console.error("Error fetching featured sections:", error);
    return null;
  }
};
