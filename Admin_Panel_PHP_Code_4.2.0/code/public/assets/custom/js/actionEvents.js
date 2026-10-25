function setStatusRadio(status, name) {
    const radioName = name || 'status';
    const value = status == 1 ? 1 : 0;
    $('input[name=' + radioName + '][value=' + value + ']').prop('checked', true);
}

function setEditImagePreview(html) {
    let url = '';

    if (html) {
        if (typeof html === 'string' && /<\s*img/i.test(html)) {
            url = $(html).find('img').attr('src') || '';
        } else if (typeof html === 'string') {
            url = html.trim();
        }
    }

    const $img = $('#edit_image_preview');
    const $container = $('#edit_image_preview_container');


    if (url && url !== '-') {

        $img.attr('src', url).show();
        $container.find('.no-image-text').remove();

    } else {

        $img.removeAttr('src').hide();

        if (!$container.find('.no-image-text').length) {
            $container.append(
                '<div class="no-image-text">No image available</div>'
            );
        }
    }
}

window.authorEvents = {
    'click .edit-data': function (e, value, row) {

         // Get the data-user-id from the clicked button
         var userId = $(e.currentTarget).data('user-id');
         var authorId = $(e.currentTarget).data('id');

        $('#telegram_link').val(row.telegram_link);
        $('#whatsapp_link').val(row.whatsapp_link);
        $('#linkedin_link').val(row.linkedin_link);
        $('#facebook_link').val(row.facebook_link);

        // Set the hidden input values
        $('#edit_id').val(authorId);
        $('#user_id').val(userId);

        // Set the status radio button if needed
        if (row.status) {
            $('input[name="author_status"][value="' + row.status + '"]').prop('checked', true);
        }
      $('input[name="auto_approve"][value="' + row.auto_approve + '"]').prop('checked', true);
    },
};


window.eNewsEvents = {
    'click .edit-data': function (e, value, row) {
        $('#filepreview').attr('href', row.attachment);
        setEditImagePreview(row.thumbnail);
        $('#edit_id').val(row.id);
        $('#edit_language').val(row.language_id).trigger('change');
        $('#edit_title').val(row.title);
        $('#edit_slug').val(row.slug);
        $('#edit_date').val(row.date);
        let des1 = tinyMCE.get('edit_des').setContent(row.description);
        $('#edit_des').val(des1);
        // $('#edit_des').val(row.description);
        $('#edit_meta_title').val(row.meta_title);
        getWordCount('edit_meta_title', 'edit_meta_title_count', '19.9px arial');
        $('#edit_meta_tags').val(row.meta_keyword);
        $('#edit_schema_markup').val(row.schema_markup);
        $('#edit_meta_description').val(row.meta_description);
        getWordCount('edit_meta_description', 'edit_meta_description_count', '12.9px arial');
        // var editSwitch = document.querySelector('#edit_status_switch');
        // var shouldBeChecked = (row.raw_status == 1);
        // if (editSwitch.checked !== shouldBeChecked) {
        //     editSwitch.click();
        // }
        setStatusRadio(row.status);



    },
};

window.staffEvents = {
    'click .edit-data': function (e, value, row) {

        $('#edit_id').val(row.id);
        $('#edit_username').val(row.username);
        $('#edit_email').val(row.email);
        $('#edit_role').val(row.role_id);
        $('input[name="status"][value="' + row.status + '"]').prop('checked', true);
    },
}

window.categoryEvents = {
     'click .edit-data': function (e, value, row) {

        $('#edit_id').val(row.id);
        $('#edit_name').val(row.category_name);
        $('#edit_language_id').val(row.language_id).trigger('change');
        $("#image_url").val(row.image_url);
        setEditImagePreview(row.image);
        $('#edit_slug').val(row.slug);
        $('#edit_meta_tags').val(row.meta_keyword);
        $('#edit_schema_markup').val(row.schema_markup);
        $('#edit_meta_title').val(row.meta_title);
        $('#edit_meta_description').val(row.description)
        getWordCount('edit_meta_description', 'edit_meta_description_count', '12.9px arial');
        getWordCount('edit_meta_title', 'edit_meta_title_count', '19.9px arial');
     }
}

window.adSpaceEvents = {
    'click .edit-data': function(e, value, row, index) {
        $('#edit_id').val(row.id);

        // Determine page/platform/placement — fallback for legacy records
        var page = row.page;
        var platform = row.platform;
        var placement = row.placement;

        if (!page && row.ad_space) {
            if (row.ad_space === 'news_details_top' || row.ad_space === 'news_details_bottom') {
                page = 'news_details';
                platform = 'both';
                placement = row.ad_space;
            } else if (row.ad_space.startsWith('featuredsection-')) {
                page = 'featured_section';
                platform = 'both';
                placement = row.ad_space;
            }
        }

        // Set platform and trigger cascade
        $('#edit_platform').val(platform).trigger('change');

        // Wait for page dropdown to populate, then set page
        setTimeout(function() {
            $('#edit_page').val(page).trigger('change');

            // Wait for placement dropdown to populate, then set placement
            setTimeout(function() {
                $('#edit_placement').val(placement);
                if (typeof updateSizeHint === 'function') {
                    updateSizeHint('edit_');
                }

                // If featured_section, load featured sections and set value
                if (page === 'featured_section' && row.language_id) {
                    $('#edit_language_id').val(row.language_id);
                    var featuredSectionId = row.ad_featured_section_id || '';
                    $.ajax({
                        url: window.getFeaturedSectionsByLanguageUrl,
                        type: "POST",
                        data: { language_id: row.language_id },
                        success: function(result) {
                            $('#edit_featured_section_id').html(result);
                            if (featuredSectionId) {
                                $('#edit_featured_section_id').val(featuredSectionId);
                                $('#edit_featured_section_id_input').val(featuredSectionId);
                            }
                        }
                    });
                } else {
                    $('#edit_language_id').val(row.language_id);
                }
            }, 50);
        }, 50);

        $("#ad_image_url").val(row.ad_image_url);
        setEditImagePreview(row.ad_image);
        var bannerType = row.banner_type || 'external_link';
        $("#edit_banner_type").val(bannerType).trigger('change');
        $("#edit_ad_url").val(row.ad_url);
        $("#edit_duration_days").val(row.duration_days || 1);
        setStatusRadio(row.status);
    }
}
window.liveStreamingEvents = {
    'click .edit-data': function (e, value, row, index) {

        $('#edit_id').val(row.id);
        $("#edit_language").val(row.language_id);
        $("#image_url").val(row.image_url);
        setEditImagePreview(row.image);
        $("#edit_title").val(row.title);
        $('#edit_type').val(row.type1).trigger('change');
        $('#url').val(row.url);
        $('#edit_meta_tags').val(row.meta_keyword);
        $('#edit_schema_markup').val(row.schema_markup);
        $('#edit_meta_description').val(row.meta_description);
        $('#edit_meta_title').val(row.meta_title);
        getWordCount('edit_meta_description', 'edit_meta_description_count', '12.9px arial');
        getWordCount('edit_meta_title', 'edit_meta_title_count', '19.9px arial');
    }
};
window.socialMediaEvents = {
    'click .edit-data': function(e, value, row, index) {
        setEditImagePreview(row.image);
        $('#edit_id').val(row.id);
        $('#edit_link').val(row.link);
    }
}
 window.tagEvents = {
    'click .edit-data': function(e, value, row, index) {
        setEditImagePreview(row.og_image);
        $('#edit_id').val(row.id);
        $("#edit_name").val(row.tag_name);
        $("#edit_language").val(row.language_id).trigger('change');
        $('#edit_slug').val(row.slug);
        $('#edit_meta_tags').val(row.meta_keyword);
        $('#edit_schema_markup').val(row.schema_markup);
        $('#edit_meta_description').val(row.description);
        $('#edit_meta_title').val(row.meta_title);
        getWordCount('edit_meta_description', 'edit_meta_description_count', '12.9px arial');
        getWordCount('edit_meta_title', 'edit_meta_title_count', '19.9px arial');
    }
};
window.seoSettingEvents = {
    'click .edit-data': function (e, value, row, index) {

        setEditImagePreview(row.og_image);
        $('#edit_id').val(row.id);
        $('#edit_language_id').val(row.language_id);
        $('#edit_page_type').val(row.page_type);
        $('#edit_meta_title').val(row.meta_title);
        $('#edit_meta_tags').val(row.meta_keyword);
        $('#edit_schema_markup').val(row.schema_markup);
        $('#edit_meta_description').val(row.meta_description)
        getWordCount('edit_meta_description', 'edit_meta_description_count', '12.9px arial');
        getWordCount('edit_meta_title', 'edit_meta_title_count', '19.9px arial');
    }
}

window.userEvents = {
    'click .edit-data': function(e, value, row, index) {

        $('#edit_id').val(row.id);
        if (row.role_id) {
            $("input[name=edit_role]").prop("checked", true);
        } else {
            $("input[name=edit_role]").prop("checked", false);
        }
        setStatusRadio(row.status, 'edit_status');
    }
};

window.subCategoryEvents = {
    'click .edit-data': function(e, value, row, index) {

        $('#edit_id').val(row.id);
        $("#image_url").val(row.image_url);
        $("#edit_language_id").val(row.language_id).trigger('change', [row.language_id, row.category_id]);
        $("#edit_name").val(row.subcategory_name);
        $('#edit_slug').val(row.slug);
    }
};
window.surveyEvents = {
    'click .edit-data': function(e, value, row, index) {

        $('#edit_id').val(row.id);
        $("#question").val(row.question);
        $("#edit_language_id").val(row.language_id);
        setStatusRadio(row.status);
    }
};
window.surveyOptionEvents = {
    'click .edit-data': function(e, value, row, index) {

        $('#edit_id').val(row.id);
        $("#edit_option").val(row.options);
    }
};
window.pagesEvents = {
    'click .edit-data': function (e, value, row, index) {

        $('#edit_id').val(row.id);
        $("#edit_language").val(row.language_id).trigger('change');
        $("#edit_title").val(row.title);
        $("#edit_slug").val(row.slug);
        $('#edit_page_type').val(row.page_type).attr('readonly', row.readonly).trigger('change');
        var des1 = tinyMCE.get('edit_page_content').setContent(row.page_content);
        $('#edit_page_content').val(des1);
        $('#edit_meta_tags').val(row.meta_keyword);
        $('#edit_schema_markup').val(row.schema_markup);
        $('#edit_meta_description').val(row.meta_description);
        $('#edit_meta_title').val(row.meta_title);
        getWordCount('edit_meta_description', 'edit_meta_description_count', '12.9px arial');
        getWordCount('edit_meta_title', 'edit_meta_title_count', '19.9px arial');
        $("#edit_meta_keywords").val(row.meta_keywords);
        setStatusRadio(row.status);
        $("input[name=status]").prop('disabled', row.readonly);
        setEditImagePreview(row.og_image);
        const pageIconHtml = row.image;
        const pageIconUrl = pageIconHtml ? ($(pageIconHtml).find('img').attr('src') || '') : '';
        const $pageIcon = $('#edit_page_icon_preview');
        if (pageIconUrl) {
            $pageIcon.attr('src', pageIconUrl).show();
        } else {
            $pageIcon.removeAttr('src').hide();
        }
    }
};
window.rssEvents = {
    'click .edit-data': function(e, value, row, index) {

        $('#edit_id').val(row.id);
        $('#edit_slug').val(row.slug);
        $("#edit_feed_name").val(row.feed_name);
        $("#edit_feed_url").val(row.feed_url);
        setStatusRadio(row.status);

        $("#edit_language_id").val(row.language_id).trigger('change', [row.language_id, row.category_id, row
            .subcategory_id, row.tag_id
        ]);
    }
};
window.feedItemEvents = {
    // delete is handled globally by .delete-form class in custom.js
};
window.videoShortLikeEvents = {
    // delete is handled globally by .delete-form class in custom.js
};
window.videoShortCommentEvents = {
    // delete is handled globally by .delete-form class in custom.js
};
 window.locationEvents = {
    'click .edit-data': function(e, value, row, index) {

        $('#edit_id').val(row.id);
        $('#name').val(row.location_name);
        $('#latitude').val(row.latitude);
        $("#longitude").val(row.longitude);
    }
}
window.languageEvents = {
    'click .edit-data': function(e, value, row, index) {

        setEditImagePreview(row.image);
        $('#edit_id').val(row.id);
        $('#edit_language').val(row.language);
        $('#edit_display_name').val(row.display_name);
        $('#edit_code').val(row.code);

        setStatusRadio(row.status);
        if (row.is_default) {
            $('#is_default').hide();
        } else {
            $('#is_default').show();
        }
        setTimeout(function() {
            const $sw = $(".editInModel");
            const target = row.isRtl_value == 1;
            if ($sw.is(':checked') !== target) {
                $sw.trigger('click');
            }
        }, 500);
    }
}
window.breakingNewsEvents = {
    'click .edit-data': function(e, value, row, index) {

        $('#edit_id').val(row.id);
        $("#image_url").val(row.image_url);
        setEditImagePreview(row.image);
        $("#edit_language").val(row.language_id);
        $("#edit_title").val(row.title);
        $('#edit_slug').val(row.slug);
        $("#edit_content_type").val(row.content).trigger('change');
        $('#edit_meta_tags').val(row.meta_keyword);
        $('#edit_schema_markup').val(row.schema_markup);
        $('#edit_meta_description').val(row.meta_description);
        $('#edit_meta_title').val(row.meta_title);
        getWordCount('edit_meta_description', 'edit_meta_description_count', '12.9px arial');
        getWordCount('edit_meta_title', 'edit_meta_title_count', '19.9px arial');
        var con_value = row.content_value;
        $('.evideo_youtube').hide();
        $('.evideo_other').hide();
        $('.evideo_upload').hide();
        if (row.content == "video_youtube") {
            $('.evideo_youtube').show();
            $('#youtube_url').val(con_value);
        } else if (row.content == "video_other") {
            $('#other_url').val(con_value);
            $('.evideo_other').show();
        } else if (row.content == "video_upload") {
            $('.evideo_upload').show();
            $("#video_url").val('public/images/breaking_news_video/' + con_value);
        }
        var des1 = tinyMCE.get('edit_des').setContent(row.description);
        $('#edit_des').val(des1);
        $('#edit_summarized_description').val(row.summarized_description);
        getWordCount('edit_summarized_description', 'edit_summarized_description_count', '12.9px arial', 0, 300, 'summarized_description');
    }
};
window.featuredSectionEvents = {
    'click .edit-data': function(e, value, row, index) {
        $('#edit_category_list').val(null).trigger('change');
        $('#edit_rss_feeds_news_type').val(null).trigger('change');
        $('#edit_category_id').val(null).trigger('change');
        $('#edit_subcategory_id').val(null).trigger('change');
        $('#edit_news_id').val(null).trigger('change');
        $('#edit_filter_type').val('').trigger('change');
        $('#edit_category_ids').html('').trigger('change');
        $('#edit_filter_category_list').hide();
        $('#edit_rss_feeds_news_section').hide();
        $('#edit_author_news_type_section').hide();
        $('#edit_filter_type_section').show();
        $('#edit_filter_news').show();

        $("#edit_language_id").val(row.language_id).trigger('change', [row.language_id, row.category_id, row
            .subcategory_id, row.news_id, row.filter_type, row.news_type, row.user_ids, row.category_list, row.rss_feeds_news_type, row.videos_type
        ]);
        $('#edit_id').val(row.id);
        $("#edit_title").val(row.title);
        $('#edit_slug').val(row.slug);
        $("#edit_schema_markup").val(row.schema_markup);
        $("#edit_videos_type").val(row.videos_type);
        if (row.news_type == "videos") {
            $('#edit_videos_option').show();
        } else {
            $('#edit_videos_option').hide();
        }
        // Handle author_news type on modal open
        if (row.news_type == "author_news") {
            $('#edit_author_news_type_section').show();
            $('#edit_filter_type_section').hide();
            $('#edit_filter_news').hide();
        } else {
            $('#edit_author_news_type_section').hide();
            $('#edit_filter_type_section').show();
            if (row.news_type != 'breaking_news') {
                $('#edit_filter_news').show();
            }
        }

        if(row.news_type == "rss_feeds_news"){
            // working
            // console.log("if edit");

            $('#edit_filter_category_list').show();
            $('#edit_rss_feeds_news_section').show();
        } else {
            $('#edit_filter_category_list').hide();
            $('#edit_rss_feeds_news_section').hide();
        }
        setEditImagePreview(row.og_image);
        $("#edit_meta_description").val(row.meta_description);
        $('#edit_meta_title').val(row.meta_title);
        $("#edit_meta_tags").val(row.meta_keyword);
        // edit_rss_feeds_news_type
        // $("#edit_rss_feeds_news_type").val(row.rss_feeds_news_type);
        getWordCount('edit_meta_description', 'edit_meta_description_count', '12.9px arial');
        getWordCount('edit_meta_title', 'edit_meta_title_count', '19.9px arial');
        setStatusRadio(row.status);
        setTimeout(function() {
            const $sw = $(".editInModel");
            const target = row.is_based_on_user_choice == "1";
            if ($sw.is(':checked') !== target) {
                $sw.trigger('click');
            }
        }, 1000);
        $("input[name=style_app][value=" + row.style_app_edit + "]").prop('checked', true);
        $("input[name=style_web][value=" + row.style_web_edit + "]").prop('checked', true);
    },
};
window.newsEvents = {
    'click .edit-data': function(e, value, row, index) {

        $('#edit_id').val(row.id);
        $("#image_url").val(row.image_url);
        setEditImagePreview(row.image);
        $('#edit_slug').val(row.slug);
        $("#edit_title").val(row.title);
        $('#edit_published_date').val(row.published_date);
        $("#edit_date").val(row.date1);
        $("#edit_location_id").val(row.location_id);
        $("#edit_show_till").val(row.show_till).prop('min', row.published_date);
        $('#edit_meta_tags').val(row.meta_keyword);
        $('#edit_schema_markup').val(row.schema_markup);
        $("#edit_content_type").val(row.content_type1).trigger('change');

        var con_value = row.content_value;
        $('.evideo_youtube').hide();
        $('.evideo_other').hide();
        $('.evideo_upload').hide();
        if (row.content_type1 == "video_youtube") {
            $('.evideo_youtube').show();
            $('#youtube_url').val(con_value);
        } else if (row.content_type1 == "video_other") {
            $('.evideo_other').show();
            $('#other_url').val(con_value);
        } else if (row.content_type1 == "video_upload") {
            $('.evideo_upload').show();
            $("#video_url").val('public/images/news_video/' + con_value);
        }
        // $('#edit_is_notification').prop('checked', false);
        setStatusRadio(row.status);
        $("#edit_is_notification").prop("checked", true).trigger("click");


        if (row.is_draft == '1' || row.is_draft == 1) {
            $('#edit_draft_switch').prop('checked', true);
            $('#edit_is_draft').val('1');
            let draftEl = $('#edit_draft_switch')[0];
            if (draftEl) {
                draftEl.dispatchEvent(new Event('change'));
            }
        } else {
            $('#edit_draft_switch').prop('checked', false);
            $('#edit_is_draft').val('0');
            let draftEl = $('#edit_draft_switch')[0];
            if (draftEl) {
                draftEl.dispatchEvent(new Event('change'));
            }
        }
        if (row.is_short_news == '1' || row.is_short_news == 1) {
            $('#edit_is_short_news_switch').prop('checked', true);
            $('#edit_is_short_news').val('1');
            let shortNewsEl = $('#edit_is_short_news_switch')[0];
            if (shortNewsEl) {
                shortNewsEl.dispatchEvent(new Event('change'));
            }
        } else {
            $('#edit_is_short_news_switch').prop('checked', false);
            $('#edit_is_short_news').val('0');
            let shortNewsEl = $('#edit_is_short_news_switch')[0];
            if (shortNewsEl) {
                shortNewsEl.dispatchEvent(new Event('change'));
            }
        }

        // Set is_comment switch state
        if (row.is_comment == '1') {
            $("#edit_comments_switch").prop("checked", true);
            $("#edit_is_comment").val(1);
            // Force update the switch UI

            let commentsEl = $('#edit_comments_switch')[0];
            if (commentsEl) {
                commentsEl.dispatchEvent(new Event('change'));
            }
        } else {
            $("#edit_comments_switch").prop("checked", false);
            $("#edit_is_comment").val(0);

            let commentsEl = $('#edit_comments_switch')[0];
            if (commentsEl) {
                commentsEl.dispatchEvent(new Event('change'));
            }
        }

        switcheryInstances1.forEach(function(switchery) {
            if (switchery.element.id === 'edit_is_notification') {

            if (row.status == 0 || row.published_date > today) {
                switchery.disable();
            } else {
                switchery.enable();
            }
        }
        });

        $('#edit_meta_description').val(row.meta_description);
        $('#edit_meta_title').val(row.meta_title);
        getWordCount('edit_meta_description', 'edit_meta_description_count', '12.9px arial');
        getWordCount('edit_meta_title', 'edit_meta_title_count', '19.9px arial');

        $("#edit_language_id").val(row.language_id).trigger('change', [row.language_id, row.category_id, row
            .subcategory_id, row.tag_id
        ]);
    },
    'click .edit-data-des': function(e, value, row, index) {
        $('input[name=edit_id]').val(row.id);
        var des1 = tinyMCE.get('edit_des').setContent(row.description);
        $('#edit_des').val(des1);
        $('#edit_summarized_description').val(row.summarized_description);
        getWordCount('edit_summarized_description', 'edit_summarized_description_count', '12.9px arial', 0, 300, 'summarized_description');
    }
};

window.videoshortsEvents = {

    'click .videoshorts-edit': function (e, value, row) {
        $('#edit_video_type').val(row.video_type).trigger('change');
        if(row.video_type == "youtubelink"){
             $('#edit_youtube_url').val(row.video_url);
        }
        $('#videopreview').attr('href', row.video_url || '');
        $('#editDataModal').modal('show');
        $('#edit_des').val(row.description);
        getWordCount('edit_des', 'edit_des_count', '12.9px arial', 0, 0, 'description');
        $('#edit_id').val(row.id);
        $('#edit_language_id').val(row.language_id).trigger('change');
        $('#edit_title').val(row.title);
        $('#edit_slug').val(row.slug);
        if (row.date) {
            $('#edit_published_date').val(row.date.split(' ')[0]);
        } else {
            $('#edit_published_date').val('');
        }

        setStatusRadio(row.status);

        setTimeout(function () {
            $('#edit_category_id').val(row.category_id).trigger('change');
            }, 650);
    }
};
window.podcastEpisodeEvents = {
    
    'click .episode-edit': function (e, value, row) {
        
        $('#editDataModal').modal('show');
        $("#edit_id").val(row.id);
        if (row.audio_url)
        {
            $('#audio_source').attr('src', row.audio_url);
            $('#audio_player')[0].load();
            $('#audio_player_container').show();
        } else {
            $('#audio_source').attr('src', '');
            $('#audio_player')[0].load();
            $('#audio_player_container').hide();
        }
        // Hidden IDs
        $('#edit_podcast_id').val(row.podcast_id);
        $('#edit_episode_id').val(row.id);
        // Episode details
        $('#edit_episode_no').val(row.episode_no).data('original-episode-no', row.episode_no);
        $('#edit_title').val(row.title);
        $('#edit_slug').val(row.slug);
        $('#edit_description').val(row.description || '');
        getWordCount('edit_description', 'edit_description_count', '12.9px arial', 0, 0, 'description');
        $('#edit_published_date').val(
                row.published_at ? row.published_at.split(' ')[0] : ''
            );
        // Source type
        $('#edit_source_type').val(row.source_type).trigger('change');

        if (row.source_type === 'youtube_link') {
            $('#edit_audio_url').val(row.audio_url);
        } else {
            $('#edit_audio_url').val('');
        }
        setEditImagePreview(row.image);
        // Status
        setStatusRadio(row.status);

        // Draft
        var checkbox = document.getElementById('edit_draft_switch');
        checkbox.checked = !!row.is_draft;

        // Dispatch change event to update Switchery UI
        checkbox.dispatchEvent(new Event('change'));

        $('input[name="is_draft"]').val(row.is_draft ? 1 : 0);
    }
};


window.podcastEvents = {

    'click .podcast-edit': function (e, value, row) {

        // Podcast ID
        $('#edit_id').val(row.id);

        // Title & slug
        $('#edit_title').val(row.title);
        $('#edit_slug').val(row.slug);

        // Description
        $('#edit_des').val(row.description || '');
        getWordCount('edit_des', 'edit_des_count', '12.9px arial', 0, 0, 'description');

        // Published date
        $('#edit_published_date').val(
            row.published_at ? row.published_at.split(' ')[0] : ''
        );
        // Status
        setStatusRadio(row.status);

        // Draft
         var checkbox = document.getElementById('edit_draft_switch');
        checkbox.checked = !!row.draft;

        // Dispatch change event to update Switchery UI
        checkbox.dispatchEvent(new Event('change'));

        $('input[name="is_draft"]').val(row.draft ? 1 : 0);
        setEditImagePreview(row.image);
        // Meta fields
        $('#edit_meta_title').val(row.meta_title);
        getWordCount('edit_meta_title', 'edit_meta_title_count', '19.9px arial');
        $('#edit_meta_tags').val(row.meta_keyword);
        $('#edit_schema_markup').val(row.schema_markup);
        $('#edit_meta_description').val(row.meta_description);
        getWordCount('edit_meta_description', 'edit_meta_description_count', '12.9px arial');
    }
};
window.alertsEvents = {
    'click .alerts-edit': function (e, value, row) {

        $('#editDataModal').modal('show');
        $('#edit_id').val(row.id);
        $('#edit_alert_type').val(row.alert_type).trigger('change');
        $('#edit_selected_symbol').val(row.symbol);
        $('#edit_selected_name').val(row.name);
        $('#edit_selected_exchange').val(row.exchange);
        $('#edit_selected_ipo_price').val(row.ipo_price);

        if (row.alert_type === 'stock') {
            $('#edit_namesearch').val(row.name + ' (' + row.symbol + ') - ' + row.exchange);
        } else if (row.alert_type === 'forex') {
            $('#edit_forex_select').val(row.symbol);
        } else if (row.alert_type === 'commodity') {
            $('#edit_commodity_select').val(row.symbol);
        } else if (row.alert_type === 'Crypto') {
            $('#edit_crypto_select').val(row.symbol);
        } else if (row.alert_type === 'IPO') {
            $('#edit_ipo_select').val(row.symbol);
        }

        setStatusRadio(row.status, 'status');
    }
};