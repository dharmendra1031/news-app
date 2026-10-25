function queryParams(p) {
    // Global bootstrap-table query params helper.
    // Extend the default params with common filters used across pages.
    return {
        // original bootstrap-table pagination/sort/search params
        sort: p.sort,
        order: p.order,
        limit: p.limit,
        offset: p.offset,
        search: p.search,

        // common filter: language
        language_id: $('#filter_language_id').val(),
    };
}


function adSpacesQueryParams(p) {

    return {
        ...p,
        language_id: $('#filter_language_id').val(),
        status: $('#filter_status').val(),
        platform: $('#filter_platform').val()
    };
}

function newsQueryParams(p) {
    return {
        ...p,
        language_id: $('#filter_language_id').val(),
        category_id: $('#filter_category_id').val(),
        subcategory_id: $('#filter_subcategory_id').val(),
        location_id: $('#filter_location_id').val(),
        user_id: $('#filter_user_id').val(),
        status: $('#filter_status').val(),
    };
}


function rssQueryParams(p) {
    return {
        ...p,
        language_id: $('#filter_language_id').val(),
        category_id: $('#filter_category_id').val(),
        subcategory_id: $('#filter_subcategory_id').val(),
        location_id: $('#filter_location_id').val(),
        user_id: $('#filter_user_id').val(),
        status: $('#filter_status').val(),
    };
}

function featuredSectionQueryParams(p) {
    return {
        ...p,
        language_id: $('#filter_language_id').val(),
        status: $('#filter_status').val(),
        news_type: $('#filter_news_type').val()
    };
}

// used in [user, comments, comments flag, send notification, category] pages table
function commonQueryParams(p) {

    return {
        ...p
    };
}

function authorQueryParams(p) {
    return {
        ...p,
        status: $('#filter_status').val(),
    };
}

function pageQueryParams(p) {
    return {
        ...p,
        language_id: $('#filter_language_id').val(),
        status: $('#filter_status').val(),
        page_type: $('#filter_page_type').val(),
    };
}


function subcategoryQueryParams(p) {
    return {
        ...p,
        language_id: $('#filter_language_id').val(),
        category_id: $('#filter_category_id').val(),
    };
}

function eNewsQueryParams(p) {
    return {
        ...p,
        language_id: $('#filter_language_id').val(),
        status: $('#filter_status').val(),
    };
}
function socialMediaQueryParams(p) {

    return {
        ...p,
    };
}
function locationParams(p) {
    return {
        ...p,
    };
}
function languageParams(p) {
    return {
        ...p,
    };
}
function breakingNewsParams(p) {
    return {
        ...p,
        language_id: $('#filter_language_id').val(),
        content_type: $('#filter_content_type').val(),
    };
}
function surveyParams(p) {
    return {
        ...p,
        language_id: $('#filter_language_id').val(),
        status: $('#filter_status').val(),
    };
}
function staffQueryParams(p) {
    return {
        ...p,
        status: $('#filter_status').val(),
    };
}
function userQueryParams(p) {
    return {
        ...p,
        status: $('#filter_status').val(),
        type: $('#filter_type').val(),
    };

}
function notificationQueryParams(p){
       return{
            ...p,
            language_id: $('#filter_language_id').val(),
            category_id: $('#filter_category_id').val(),
            subcategory_id: $('#filter_subcategory_id').val(),
       };
}

function podcastQueryParams(p) {
    return {
        ...p,
        status: $('#filter_status').val(),
    };
}
