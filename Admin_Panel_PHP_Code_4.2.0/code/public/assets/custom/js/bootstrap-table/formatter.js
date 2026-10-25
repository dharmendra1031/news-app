// news table
function isDraftNewsFormatter(value, row, index) {
    if (value == '1') {
        return '<span class="badge badge-warning">' + trans('yes') + '</span>';
    } else {
        return '<span class="badge badge-success">' + trans('no') + '</span>';
    }
}

// author table
function statusFormatter(value, row, index) {
    // Ensure translations object exists
    // var trans = typeof translations !== 'undefined' ? translations : {};

    if (value == 'pending') {
        // return '<span class="badge badge-warning">' + trans.pending || 'Pending') + '</span>';
        return '<span class="badge badge-warning">' + trans('pending') + '</span>';
    } else if (value == 'approved') {
        return '<span class="badge badge-success">' + trans('approved') + '</span>';
    } else if (value == 'rejected') {
        return '<span class="badge badge-danger">' + trans('rejected') + '</span>';
    }
    return '';
}


// table column text show more and less formatter
function textFormatter(value, row, index) {
    if (value?.length > 100) {
        return '<div class="short-description">' + value.substring(0, 50) +
            '... <a href="#" class="view-more" data-index="' + index + '">' + trans('see_more') + '</a></div>' +
            '<div class="full-description" style="display:none;">' + value +
            ' <a href="#" class="view-more" data-index="' + index + '">' + trans('see_less') + '</a></div>';
    } else {
        return value;
    }
}

// news table
// function smallTextFormatter (value, row, index){
//     if (!value) return '';

//     // Remove heading tags and other large tags
//     let sanitized = value.replace(/<\/?h[1-6][^>]*>/gi, '');

//     // Optionally, remove all HTML comments
//     sanitized = sanitized.replace(/<!--.*?-->/gs, '');

//     return `<small style="font-size: 1.0rem;">${sanitized}</small>`;
// }

// breaking news
function descriptionFormatter(value, row, index) {
    if (!value) return '';
    let tempDiv = document.createElement('div');
    tempDiv.innerHTML = value;
    let textContent = tempDiv.textContent || tempDiv.innerText || '';

    if (textContent.length > 20) {
        return '<div class="description-container">' +
            '<div class="short-desc">' + textContent.substring(0, 20) + '...</div>' +
            '<div class="full-desc" style="display:none">' + value + '</div>' +
            '<a href="javascript:void(0)" class="toggle-desc" data-show="more">' + trans('see_more') + '</a>' +
            '</div>';
    }
    return value;
}

// news table
function dateFormate(value, row) {
    if (value && value !== '0000-00-00') {
        var date = new Date(value);
        var yy = date.getFullYear();
        var mm = date.getMonth() + 1; // getMonth() is zero-based
        var dd = date.getDate();
        return dd.toString().padStart(2, '0') + '-' + mm.toString().padStart(2, '0') + '-' + yy;
    }
    return '00-00-0000';
}
function MM_DD_YYYY_dateFormate(value, row) {
    if (value && value !== '0000-00-00') {
        var date = new Date(value);
        var mm = date.getMonth() + 1; // getMonth() is zero-based
        var dd = date.getDate();
        var yy = date.getFullYear();
        return mm.toString().padStart(2, '0') + '-' + dd.toString().padStart(2, '0') + '-' + yy;
    }
    return '00-00-0000';
}


function eNewsStatusFormatter(value, row, index) {
    if (value == 0) {
        return '<span class="badge badge-danger">' + trans('deactive') + '</span>';
    } else if (value == 1) {
        return '<span class="badge badge-success">' + trans('active') + '</span>';
    }
    return '-';
}
function userStatusFormatter(value, row, index) {
    if (value == 0) {
        return '<span class="badge badge-danger">' + trans('deactive') + '</span>';
    } else if (value == 1) {
        return '<span class="badge badge-success">' + trans('active') + '</span>';
    }
    return '-';
}
function userRoleFormatter(value, row, index) {
    if (value == 0) {
        return '<span class="badge badge-danger">' + trans('no') + '</span>';
    } else if (value == 1) {
        return '<span class="badge badge-success">' + trans('yes') + '</span>';
    }
    return '-';
}
function userTypeFormatter(value, row, index) {
    // <em class="' . $icon[trim($row->type)] . ' fa-2x"></em>' : '<em class="' . $icon['email'] . ' fa-2x"></em>
    if (value == 'email') {
        return '<em class="far fa-envelope-open fa-2x"></em>';
    } else if (value == 'google') {
        return '<em class="fab fa-google-plus-square text-danger fa-2x"></em>';
    } else if (value == 'facebook') {
        return '<em class="fab fa-facebook-square text-primary fa-2x"></em>';
    } else if (value == 'apple') {
        return '<em class="fab fa-apple fa-2x"></em>';
    } else if (value == 'mobile') {
        return '<em class="fas fa-phone-square fa-2x"></em>';
    }
    return '-';
}
function isShortNewsFormatter(value, row, index) {
    if (value == '1') {
        return '<span class="badge badge-warning">' + trans('yes') + '</span>';
    } else {
        return '<span class="badge badge-success">' + trans('no') + '</span>';
    }
}

function newsCountFormatter(value, row, index) {
    return '<span class="btn-icon btn-sm btn-success">' + value + '</span>';
}
function rowOrderFormatter(value, row, index) {
    return '<span class="btn-icon btn-sm btn-warning">' + value + '</span>';
}
function generalImageFormatter(value, row, index) {
    if(!value)
        return '-';
    return '<a href="' + value + '" data-toggle="lightbox" data-title="Image"><img  class = "images_border" src="' + value + '" height="50" width="50"></a>';
}
function attachmentFormatter(value, row, index) {
    // icon size 16px
    return value ? '<a href="' + value + '" target="_blank"><i class="fas fa-file-pdf" style="font-size: 36px;"></i></a>' : '-';
}
function staffStatusFormatter(value, row, index) {
    if (value == 1) {
        return '<span class="badge badge-success">' + trans('active') + '</span>';
    } else if (value == 0) {
        return '<span class="badge badge-danger">' + trans('deactive') + '</span>';
    }
    return '-';
}
function crawledFeedsCountsFormatter(value, row, index){
    // route to crawled feeds list inside the span tag
    return '<span class="btn-icon btn-sm btn-info"><a href="' + row.crawled_feeds_counts_url + '" style="color: white;">' + value + '</a></span>';
}
function feedItemImageFormatter(value, row, index) {
    if (value) {
        // return '<a href="' + value + '" data-toggle="lightbox" data-title="Image" target="_blank"><img class="images_border" src="' + value + '" height="50" width="50" style="object-fit: cover;"></a>';
        return '<a href="' + value + '" target="_blank">' +
       '<img class="images_border" src="' + value + '" height="50" width="50" style="object-fit: cover;">' +
       '</a>';
    }
    return '-';
}
function feedItemUrlFormatter(value, row, index) {
    if (value) {
        return '<a href="' + value + '" target="_blank" title="' + value + '"><i class="fas fa-external-link-alt"></i> ' + trans('open') + '</a>';
    }
    return '-';
}
function adSpaceStatusFormatter(value, row, index) {
    if (value == 0) {
        return '<span class="badge badge-danger">' + trans('deactive') + '</span>';
    } else if (value == 1) {
        return '<span class="badge badge-success">' + trans('active') + '</span>';
    }
    return '-';
}

// video shorts likes count badge -> links to likes detail page
function videoShortLikesFormatter(value, row, index) {
    var count = (value === undefined || value === null) ? 0 : value;
    return '<span class="btn-icon btn-sm btn-info"><a href="' + row.likes_url + '" class="text-white" title="' + trans('likes') + '">' + count + '</a></span>';
}

// video shorts comments count badge -> links to comments detail page
function videoShortCommentsFormatter(value, row, index) {
    var count = (value === undefined || value === null) ? 0 : value;
    return '<span class="btn-icon btn-sm btn-info"><a href="' + row.comments_url + '" class="text-white" title="' + trans('comments') + '">' + count + '</a></span>';
}

function videoShortStatusFormatter(value, row, index) {
    if (value == 0) {
        return '<span class="badge badge-danger">' + trans('deactive') + '</span>';
    } else if (value == 1) {
        return '<span class="badge badge-success">' + trans('active') + '</span>';
    }
    return '-';
}
function pageFormatter(value, row, index){
    switch(value){
        case "home_page":
            return trans("home_page");
            break;
        case "news_details":
            return trans("news_details");
            break;
        case "featured_section":
            return trans("featured_section");
            break;
        case "news_page":
            return trans("news_page");
            break;
        case "news_details_screen":
            return trans("news_details_screen");
            break;
        default:
            return "-";
    }
}
function placementFormatter(value, row, index){
       switch(value){
        case "news_details_top":
            return trans("news_details_top");
            break;
        case "news_details_bottom":
            return trans("news_details_bottom");
            break;
        case "top":
            return trans("top");
            break;
        case "bottom":
            return trans("bottom");
            break; 
        case "above":
            return trans("above");
            break; 
        case "right_side":
            return trans("right_side");
            break;
       }   
}
  function platformFormatter(value, row, index){
     switch(value){
        case "app":
            return trans("app");
            break;
        case "web":
            return trans("web");
            break;
    }
  }
function bannerTypeFormatter(value, row, index){
    switch(value){
        case "banner_only":
            return trans("banner_only");
            break;
        case "external_link":
            return trans("external_link");
            break;
    }
}
 function endDateFormatter(value, row) {

            if (!value) {
                return "<span>-<br><small>"+ trans('expired') +"</small></span>";
            }
            var parts = value.split('-');
            var formatted = parts[2] + '-' + parts[1] + '-' + parts[0];

            var endDate = new Date(value);
            var today = new Date();

            endDate.setHours(0, 0, 0, 0);
            today.setHours(0, 0, 0, 0);

            if (endDate < today) {
                return "<span>" + formatted + "<br><small>"+ trans('expired') +"</small></span>";
            }
            var diffTime = endDate - today;
            var daysLeft = Math.floor(diffTime / (1000 * 60 * 60 * 24));

            return "<span>" + formatted + "<br><small>"+ daysLeft +" "+ trans('days_left') +"</small></span>";
}
function publishDateFormatter(value, row, index) {
    if (!value) return '-';

    const date = new Date(value);

    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();

    return `${day}-${month}-${year}`;
}

function videoUrlFormatter(value, row, index) {
    if (!value) return '-';

    return '<button class="btn btn-sm btn-info video-play-btn" ' +
        'data-url="' + value + '" ' +
        'data-type="' + row.video_type + '" ' +
        'data-title="' + (row.title || '').replace(/"/g, '&quot;') + '" ' +
        'title="' + (trans('video_preview') || 'Video Preview') + '">' +
        '<i class="fas fa-play"></i></button>';
}
function autoApproveformatter(value,row,index){
    if (value == 0) {
        return '<span class="badge badge-danger">' + trans('disabled') + '</span>';
    } else if (value == 1) {
        return '<span class="badge badge-success">' + trans('enabled') + '</span>';
    }
    return '-';
}
function alertStatusFormatter(value, row, index) { 
    if (value == 0) {
        return '<span class="badge badge-danger">' + trans('deactive') + '</span>';
    } else if (value == 1) {
        return '<span class="badge badge-success">' + trans('active') + '</span>';
    }
    return '-';
}
function isDraftFormatter(value, row, index) {
    if (value == 1) {
        return '<span class="badge badge-success">' + trans('active') + '</span>';
    } else if (value == 0) {
        return '<span class="badge badge-danger">' + trans('inactive') + '</span>';
    }
    return '-';
}

function audioUrlFormatter(value, row, index) {
    if (!value) return '-';
    return '<a href="' + value + '" target="_blank" class="btn btn-sm btn-info"><i class="fas fa-external-link-alt mr-1"></i>' + trans('open') + '</a>';
}
function sourceTypeFormatter(value, row, index) {
    if (value === 'upload') {
        return trans('upload');
    } else if (value === 'youtube_link') {
        return trans('youtube_link');
    }
    return '-';
}
function videoTypeFormatter(value, row, index) {
    if (value === 'youtubelink') { 
        return trans('youtubelink'); 
    } else if (value === 'video_upload') { 
        return trans('video_upload'); 
    } 
    return '-'; 
}