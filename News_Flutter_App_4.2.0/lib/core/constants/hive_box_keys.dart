//Authbox keys
const String authBoxKey = "authBox";
const String jwtTokenKey = "jwtToken";
const String isLogInKey = "isLogIn";
const String userIdKey = "userId";
const String userNameKey = "userName";
const String userMobKey = "userMob";
const String userEmailKey = "userEmail";
const String userProfileKey = "userProfile";
const String userRoleKey = "userRole";
const String userStatusKey = "userStatus";
const String userTypeKey = "Type";
const String authorWhatsappLinkKey = "whatsAppLink";
const String authorTelegramLinkKey = "telegramLink";
const String authorfacebookLinkKey = "facebookLink";
const String authorLinkedInLinkKey = "linkedInLink";
const String authorBioKey = "authorBio";
const String authorStatusKey = "authorStatus";

//Settings box keys
const String settingsBoxKey = "settings";
const String currentLanguageCodeKey = "currentLanguageCode";
const String currentLanguageIDKey = "currentLanguageId";
const String currentLanguageRTLKey = "currentLanguageRTL";
const String introSliderKey = "introSlider";
const String currentThemeKey = "currentTheme";
const String notificationKey = "notification";
const String tokenKey = "token";
const String historyListKey = "historyList";
const String notificationEnabledKey = "notificationEnabled";
const String newsFontSizeKey = "newsFontSize";

/// Per-type notification preferences (a `Map<String, bool>` keyed by the
/// [NotificationPreferenceItem.id]s) stored inside the settings box.
const String notificationPreferencesKey = "notificationPreferences";

//Location box keys
const String locationCityBoxKey = "locationCity";
const String latitudeKey = "Latitude";
const String longitudeKey = "Longitude";

///VideoPreference
const String videoPreferenceKey = "videoPreference";
const String videoStyle = 'videoStyle';

//Podcast box keys
/// No longer opened — listening history is server-side only. Kept so the stale
/// box left by earlier versions can be deleted from disk on startup.
const String podcastHistoryBoxKey = "podcast_history_box";
const String podcastDownloadsBoxKey = "podcast_downloads_box";
