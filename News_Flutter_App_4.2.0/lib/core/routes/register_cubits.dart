import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/add_edit_news/blocs/add_news_cubit.dart';
import 'package:news/features/add_edit_news/blocs/tag_cubit.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/authentication/cubits/delete_user_cubit.dart';
import 'package:news/features/authentication/cubits/register_token_cubit.dart';
import 'package:news/features/authentication/cubits/social_signup_cubit.dart';
import 'package:news/features/authentication/cubits/update_user_cubit.dart';
import 'package:news/features/author/cubits/author_cubit.dart';
import 'package:news/features/author/cubits/author_news_cubit.dart';
import 'package:news/features/bookmarks/cubits/update_bookmark_cubit.dart';
import 'package:news/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:news/commons/cubits/connectivity_cubit.dart';
import 'package:news/commons/cubits/font_size_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/update_like_and_dislike_cubit.dart';
import 'package:news/commons/cubits/news_by_id_cubit.dart';
import 'package:news/features/news/cubits/news_comment/delete_comment_cubit.dart';
import 'package:news/features/news/cubits/news_comment/flag_comment_cubit.dart';
import 'package:news/features/news/cubits/news_comment/like_and_dislike_comm_cubit.dart';
import 'package:news/features/news/cubits/news_comment/set_comment_cubit.dart';
import 'package:news/features/notification_preferences/cubits/notification_preference_cubit.dart';
import 'package:news/features/preferences/blocs/set_user_preference_cat_cubit.dart';

import 'package:news/features/preferences/blocs/user_by_category_cubit.dart';
import 'package:news/commons/cubits/adspace/adspace_home_page_cubit.dart';
import 'package:news/commons/cubits/adspace/adSpaces_news_details_cubit.dart';
import 'package:news/features/add_edit_news/blocs/add_tag_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/news/cubits/breaking_news_cubit.dart';
import 'package:news/features/category/cubits/category_cubit.dart';
import 'package:news/features/news/cubits/comment_news_cubit.dart';
import 'package:news/features/news/cubits/delete_image_id.dart';
import 'package:news/features/news/cubits/delete_user_news_cubit.dart';
import 'package:news/features/enews/cubits/enews_cubit.dart';
import 'package:news/features/homepage/cubits/feature_section_cubit.dart';
import 'package:news/features/homepage/cubits/general_news_cubit.dart';
import 'package:news/features/rss_feed/cubits/get_rss_feeds_cubit.dart';
import 'package:news/features/news/cubits/get_survey_answer_cubit.dart';
import 'package:news/commons/cubits/get_user_data_by_id_cubit.dart';
import 'package:news/features/add_edit_news/blocs/get_user_drafted_news_cubit.dart';
import 'package:news/features/add_edit_news/blocs/get_user_news_cubit.dart';
import 'package:news/features/language/cubits/language_cubit.dart';
import 'package:news/features/language/cubits/language_json_cubit.dart';
import 'package:news/features/live_streaming/cubits/live_stream_cubit.dart';
import 'package:news/features/homepage/cubits/location_city_cubit.dart';
import 'package:news/features/dynamic_pages/cubits/other_pages_cubit.dart';
import 'package:news/features/dynamic_pages/cubits/privacy_terms_cubit.dart';
import 'package:news/features/news/cubits/related_news_cubit.dart';
import 'package:news/features/rss_feed/cubits/rss_feed_cubit.dart';
import 'package:news/features/homepage/cubits/section_by_id_cubit.dart';
import 'package:news/features/news/cubits/set_news_views_cubit.dart';
import 'package:news/features/news/cubits/set_survey_answer_cubit.dart';
import 'package:news/commons/cubits/setting_cubit.dart';
import 'package:news/features/news/cubits/short_news_cubit.dart';
import 'package:news/features/add_edit_news/blocs/slug_check_cubit.dart';
import 'package:news/features/news/cubits/slug_news_cubit.dart';
import 'package:news/features/category/cubits/subcategory_cubit.dart';
import 'package:news/features/news/cubits/survey_question_cubit.dart';
import 'package:news/features/news/cubits/tag_news_cubit.dart';
import 'package:news/commons/cubits/theme_cubit.dart';
import 'package:news/features/add_edit_news/blocs/update_bottomsheet_content_cubit.dart';
import 'package:news/features/reels/cubits/video_short_comment_cubit.dart';
import 'package:news/features/reels/cubits/video_short_like_dislike_cubit.dart';
import 'package:news/features/reels/cubits/video_short_set_comment_cubit.dart';
import 'package:news/features/reels/cubits/video_short_share_cubit.dart';
import 'package:news/features/reels/cubits/video_short_view_cubit.dart';
import 'package:news/features/reels/cubits/video_shorts_cubit.dart';
import 'package:news/features/videos/cubits/videos_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_bookmark_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_cubit.dart';
import 'package:news/features/podcast/cubits/manage_episode_cubit.dart';
import 'package:news/features/podcast/cubits/manage_podcast_cubit.dart';
import 'package:news/features/podcast/cubits/my_episodes_cubit.dart';
import 'package:news/features/podcast/cubits/my_podcasts_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_episodes_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_history_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_player_cubit.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';
import 'package:news/features/alerts/cubits/alerts_cubit.dart';
import 'package:news/features/alerts/repositories/alerts_repository.dart';
import 'package:news/features/homepage/cubits/weather_cubit.dart';
import 'package:news/features/add_edit_news/repositories/add_news_repository.dart';
import 'package:news/commons/repositories/app_system_setting/system_repository.dart';
import 'package:news/features/authentication/repositories/auth_repository.dart';
import 'package:news/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:news/features/news/repositories/breaking_news/break_news_repository.dart';
import 'package:news/features/category/repositories/category_repository.dart';
import 'package:news/features/news/repositories/comment_news/comm_news_repository.dart';
import 'package:news/features/news/repositories/delete_image_id/delete_image_repository.dart';
import 'package:news/features/add_edit_news/repositories/delete_user_news/delete_user_news_repository.dart';
import 'package:news/features/enews/repositories/enews_repository.dart';
import 'package:news/features/homepage/repositories/featured_section/section_repository.dart';
import 'package:news/features/news/repositories/get_survey_answer/get_survey_ans_repository.dart';
import 'package:news/commons/repositories/get_user_by_id/get_user_by_id_repository.dart';
import 'package:news/features/add_edit_news/repositories/get_user_news/get_user_news_repository.dart';
import 'package:news/features/language/repositories/language_json/language_json_repository.dart';
import 'package:news/features/news/repositories/like_and_dislike_news/like_and_dislike_news_repository.dart';
import 'package:news/features/live_streaming/repositories/live_stream_repository.dart';
import 'package:news/commons/repositories/news_by_id/news_by_id_repository.dart';
import 'package:news/features/news/repositories/news_comment/delete_comment/delete_comm_repository.dart';
import 'package:news/features/news/repositories/news_comment/flag_comment/flag_comm_repository.dart';
import 'package:news/features/news/repositories/news_comment/like_and_dislike_comment/like_and_dislike_comm_repository.dart';
import 'package:news/features/news/repositories/news_comment/set_comment/set_com_repository.dart';
import 'package:news/features/dynamic_pages/repositories/other_pages_repository.dart';
import 'package:news/features/news/repositories/related_news/related_news_repository.dart';
import 'package:news/features/homepage/repositories/section_by_id/section_by_id_repository.dart';
import 'package:news/features/news/repositories/set_news_views/set_news_views_repository.dart';
import 'package:news/features/news/repositories/set_survey_answer/set_survey_ans_repository.dart';
import 'package:news/features/preferences/repositories/set_user_pref_cat_repository.dart';
import 'package:news/features/notification_preferences/repositories/notification_preference_repository.dart';
import 'package:news/commons/repositories/settings/setting_repository.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/features/news/repositories/short_news/short_news_repository.dart';
import 'package:news/features/category/repositories/subcategory/subcat_repository.dart';
import 'package:news/features/news/repositories/survey_question/survey_que_repository.dart';
import 'package:news/features/add_edit_news/repositories/add_tag_repository.dart';
import 'package:news/commons/repositories/tag/tag_repository.dart';
import 'package:news/features/news/repositories/tag_news/tag_news_repository.dart';
import 'package:news/features/preferences/repositories/user_by_cat_repository.dart';
import 'package:news/features/videos/repositories/videos_repository.dart';
import 'package:news/features/language/repositories/language/language_repository.dart';
import 'package:nested/nested.dart';

class RegisterCubits {
  List<SingleChildWidget> providers = [
    BlocProvider(create: (_) => ConnectivityCubit(ConnectivityService())),
    BlocProvider<AppConfigurationCubit>(
        create: (context) => AppConfigurationCubit(SystemRepository())),
    BlocProvider<SettingsCubit>(
        create: (_) => SettingsCubit(SettingsRepository())),
    BlocProvider<AppLocalizationCubit>(
        create: (_) => AppLocalizationCubit(SettingsLocalDataRepository())),
    BlocProvider<ThemeCubit>(
        create: (_) => ThemeCubit(SettingsLocalDataRepository())),
    BlocProvider<FontSizeCubit>(
        create: (_) => FontSizeCubit(SettingsLocalDataRepository())),
    BlocProvider<LanguageJsonCubit>(
        create: (_) => LanguageJsonCubit(LanguageJsonRepository())),
    BlocProvider<LanguageCubit>(
        create: (context) => LanguageCubit(LanguageRepository())),
    BlocProvider<SectionCubit>(
        create: (_) => SectionCubit(SectionRepository())),
    BlocProvider<PrivacyTermsCubit>(
        create: (_) => PrivacyTermsCubit(OtherPageRepository())),
    BlocProvider<VideoCubit>(create: (_) => VideoCubit(VideoRepository())),
    BlocProvider<VideoShortsCubit>(create: (_) => VideoShortsCubit()),
    BlocProvider<VideoShortLikeDislikeCubit>(
        create: (_) => VideoShortLikeDislikeCubit()),
    BlocProvider<VideoShortCommentCubit>(
        create: (_) => VideoShortCommentCubit()),
    BlocProvider<VideoShortSetCommentCubit>(
        create: (_) => VideoShortSetCommentCubit()),
    BlocProvider<VideoShortShareCubit>(create: (_) => VideoShortShareCubit()),
    BlocProvider<VideoShortViewCubit>(create: (_) => VideoShortViewCubit()),
    BlocProvider<NewsByIdCubit>(
        create: (_) => NewsByIdCubit(NewsByIdRepository())),
    BlocProvider<OtherPageCubit>(
        create: (_) => OtherPageCubit(OtherPageRepository())),
    BlocProvider<LiveStreamCubit>(
        create: (_) => LiveStreamCubit(LiveStreamRepository())),
    BlocProvider<CategoryCubit>(
        create: (_) => CategoryCubit(CategoryRepository())),
    BlocProvider<SubCategoryCubit>(
        create: (_) => SubCategoryCubit(SubCategoryRepository())),
    BlocProvider<SurveyQuestionCubit>(
        create: (_) => SurveyQuestionCubit(SurveyQuestionRepository())),
    BlocProvider<SetSurveyAnsCubit>(
        create: (_) => SetSurveyAnsCubit(SetSurveyAnsRepository())),
    BlocProvider<GetSurveyAnsCubit>(
        create: (_) => GetSurveyAnsCubit(GetSurveyAnsRepository())),
    BlocProvider<CommentNewsCubit>(
        create: (_) => CommentNewsCubit(CommentNewsRepository())),
    BlocProvider<RelatedNewsCubit>(
        create: (_) => RelatedNewsCubit(RelatedNewsRepository())),
    BlocProvider<SocialSignUpCubit>(
        create: (_) => SocialSignUpCubit(AuthRepository())),
    BlocProvider<AuthCubit>(create: (_) => AuthCubit(AuthRepository())),
    BlocProvider<RegisterTokenCubit>(
        create: (_) => RegisterTokenCubit(AuthRepository())),
    BlocProvider<UserByCatCubit>(
        create: (_) => UserByCatCubit(UserByCatRepository())),
    BlocProvider<SetUserPrefCatCubit>(
        create: (_) => SetUserPrefCatCubit(SetUserPrefCatRepository())),
    BlocProvider<NotificationPreferenceCubit>(
        create: (_) =>
            NotificationPreferenceCubit(NotificationPreferenceRepository())),
    BlocProvider<UpdateUserCubit>(
        create: (_) => UpdateUserCubit(AuthRepository())),
    BlocProvider<DeleteUserCubit>(
        create: (_) => DeleteUserCubit(AuthRepository())),
    BlocProvider<BookmarkCubit>(
        create: (_) => BookmarkCubit(BookmarkRepository())),
    BlocProvider<UpdateBookmarkStatusCubit>(
        create: (_) => UpdateBookmarkStatusCubit(BookmarkRepository())),
    BlocProvider<LikeAndDisLikeCubit>(
        create: (_) => LikeAndDisLikeCubit(LikeAndDisLikeRepository())),
    BlocProvider<UpdateLikeAndDisLikeStatusCubit>(
        create: (_) =>
            UpdateLikeAndDisLikeStatusCubit(LikeAndDisLikeRepository())),
    BlocProvider<BreakingNewsCubit>(
        create: (_) => BreakingNewsCubit(BreakingNewsRepository())),
    BlocProvider<ShortNewsCubit>(
        create: (_) => ShortNewsCubit(ShortNewsRepository())),
    BlocProvider<TagNewsCubit>(
        create: (_) => TagNewsCubit(TagNewsRepository())),
    BlocProvider<SetCommentCubit>(
        create: (_) => SetCommentCubit(SetCommentRepository())),
    BlocProvider<LikeAndDislikeCommCubit>(
        create: (_) => LikeAndDislikeCommCubit(LikeAndDislikeCommRepository())),
    BlocProvider<DeleteCommCubit>(
        create: (_) => DeleteCommCubit(DeleteCommRepository())),
    BlocProvider<SetFlagCubit>(
        create: (_) => SetFlagCubit(SetFlagRepository())),
    BlocProvider<AddNewsCubit>(
        create: (_) => AddNewsCubit(AddNewsRepository())),
    BlocProvider<TagCubit>(create: (_) => TagCubit(TagRepository())),
    BlocProvider<AddTagCubit>(create: (_) => AddTagCubit(AddTagRepository())),
    BlocProvider<GetUserNewsCubit>(
        create: (_) => GetUserNewsCubit(GetUserNewsRepository())),
    BlocProvider<DeleteUserNewsCubit>(
        create: (_) => DeleteUserNewsCubit(DeleteUserNewsRepository())),
    BlocProvider<DeleteImageCubit>(
        create: (_) => DeleteImageCubit(DeleteImageRepository())),
    BlocProvider<GetUserByIdCubit>(
        create: (_) => GetUserByIdCubit(GetUserByIdRepository())),
    BlocProvider<SectionByIdCubit>(
        create: (_) => SectionByIdCubit(SectionByIdRepository())),
    BlocProvider<SetNewsViewsCubit>(
        create: (_) => SetNewsViewsCubit(SetNewsViewsRepository())),
    BlocProvider<AdSpacesNewsDetailsCubit>(
        create: (_) => AdSpacesNewsDetailsCubit()),
    BlocProvider<AdSpaceHomePageCubit>(create: (_) => AdSpaceHomePageCubit()),
    BlocProvider<LocationCityCubit>(create: (_) => LocationCityCubit()),
    BlocProvider<BottomSheetCubit>(create: (_) => BottomSheetCubit()),
    BlocProvider<SlugCheckCubit>(create: (_) => SlugCheckCubit()),
    BlocProvider<GeneralNewsCubit>(create: (_) => GeneralNewsCubit()),
    BlocProvider<RSSFeedCubit>(create: (_) => RSSFeedCubit()),
    BlocProvider<GetRssFeedsCubit>(create: (_) => GetRssFeedsCubit()),
    BlocProvider<SlugNewsCubit>(create: (_) => SlugNewsCubit()),
    BlocProvider<WeatherCubit>(create: (_) => WeatherCubit()),
    BlocProvider<AuthorCubit>(create: (_) => AuthorCubit()),
    BlocProvider<AuthorNewsCubit>(create: (_) => AuthorNewsCubit()),
    BlocProvider<GetUserDraftedNewsCubit>(
        create: (_) => GetUserDraftedNewsCubit()),
    BlocProvider<ENewsCubit>(create: (_) => ENewsCubit(ENewsRepository())),
    BlocProvider<PodcastPlayerCubit>(
        create: (_) => PodcastPlayerCubit(PodcastRepository())),
    BlocProvider<PodcastCubit>(
        create: (_) => PodcastCubit(PodcastRepository())),
    BlocProvider<PodcastEpisodesCubit>(
        create: (_) => PodcastEpisodesCubit(PodcastRepository())),
    BlocProvider<MyPodcastsCubit>(
        create: (_) => MyPodcastsCubit(PodcastRepository())),
    BlocProvider<MyEpisodesCubit>(
        create: (_) => MyEpisodesCubit(PodcastRepository())),
    BlocProvider<ManagePodcastCubit>(
        create: (_) => ManagePodcastCubit(PodcastRepository())),
    BlocProvider<ManageEpisodeCubit>(
        create: (_) => ManageEpisodeCubit(PodcastRepository())),
    BlocProvider<PodcastBookmarkCubit>(
        create: (_) => PodcastBookmarkCubit(PodcastRepository())),
    BlocProvider<PodcastHistoryCubit>(
        create: (_) => PodcastHistoryCubit(PodcastRepository())),
    BlocProvider<AlertsCubit>(create: (_) => AlertsCubit(AlertsRepository())),
  ];
}
