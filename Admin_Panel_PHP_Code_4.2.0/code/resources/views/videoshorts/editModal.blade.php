<div class="modal fade" id="editDataModal">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('edit') . ' ' . __('news_buzz') }}</h4>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <form id="update_form" method="POST" action="{{ url('video_shorts') }}">
                @csrf
                @method('PUT')
                <input type='hidden' name="edit_id" id="edit_id" value='' />
                <input type='hidden' name="image_url" id="image_url" value='' />
                <input type='hidden' name="video_url" id="video_url" value='' />
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6 col-sm-12">
                            <div class="form-group">
                                <label class="required">{{ __('language') }}</label>
                                <select id="edit_language_id" name="language" class="form-control" required>
                                    @if (count($languageList) > 1)
                                        <option value="">{{ __('select') . ' ' . __('language') }}
                                        </option>
                                    @endif
                                    @foreach ($languageList as $row)
                                        <option value="{{ $row->id }}" data-name="{{ $row->language }}">{{ $row->language }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>
                            @if (is_category_enabled() == 1)
                                <div class="form-group">
                                    <label class="required">{{ __('category') }}</label>
                                    <select id="edit_category_id" name="category_id" class="form-control" required>
                                        <option value="">{{ __('select') . ' ' . __('category') }}</option>
                                        @foreach ($categoryList as $row)
                                            <option value="{{ $row->id }}">{{ $row->category_name }}
                                            </option>
                                        @endforeach
                                    </select>
                                </div>
                            @endif
                            <div class="form-group">
                                <label>{{ __('description') }}</label>
                                <textarea id="edit_des" name="des" class="form-control"
                                    oninput="getWordCount('edit_des','edit_des_count','12.9px arial',0,0,'description')"></textarea>
                                <small id="edit_des_count" class="form-text seo-hint text-muted" style="display:none"></small>
                            </div>
                            <div class="form-group" >
                                <select name="video_type" id="edit_video_type" class="form-control" required>
                                <option value="video_upload">{{ __('video_uploads') }}</option>
                                <option value="youtubelink">{{ __('video_youtube') }}</option>
                            </select>
                            </div>
                            <div class="form-group edit_video_youtube">
                                <label class="required">{{ __('youtube_url') }}</label>
                                <input type="url" name="youtube_url" id="edit_youtube_url" class="form-control edit_youtube_url">
                            </div>

                            <div class="form-group edit_video_upload">
                                <label>{{ __('video_uploads') }}</label>
                                <small>({{ __('max_size_25mb') }})</small>
                                <a id="videopreview" href="" target="_blank">{{ __('view_current_video') }}</a>
                                <input name="video_file" type="file" class="filepond-video" id="edit_video_file">
                            </div>
                        </div>
                        <div class="col-md-6 col-sm-12">
                            <div class="form-group">
                                <label class="required">{{ __('title') }}</label>
                                <input type="text" name="title" id="edit_title" class="form-control"
                                    placeholder="news title" required data-slug-table="video_shorts"
                                    data-slug-target="#edit_slug" data-slug-id="#edit_id">
                            </div>
                            <div class="form-group">
                                <label class="required">{{ __('slug') }}</label><span
                                    class="">({{__('english_only')}})</span>
                                <input type="text" name="slug" id="edit_slug" class="form-control"
                                    placeholder="{{ __('slug') }}" required>
                                <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                            </div>
                            <div class="form-group">
                                <label>{{ __('date') }}</label>
                                <input id="edit_published_date" name="published_date" type="date" class="form-control">
                            </div>

                            <div class="form-group ">
                                <label>{{ __('status') }}</label><br>
                                <div id="status1" class="btn-group">
                                    <label class="btn btn-success" data-toggle-class="btn-primary"
                                        data-toggle-passive-class="btn-default">
                                        <input type="radio" name="status" value="1" checked>{{ __('active') }}
                                    </label>
                                    <label class="btn btn-danger" data-toggle-class="btn-primary"
                                        data-toggle-passive-class="btn-default">
                                        <input type="radio" name="status" value="0">{{ __('deactive') }}
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal">{{ __('close') }}</button>
                    <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                </div>
        </div>

        </form>
    </div>
</div>
</div>
