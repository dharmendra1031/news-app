@can('podcast-create')
<div class="col-md-12 d-flex justify-content-end">
    <button type="button" class="btn btn-primary mb-3 ml-1" id="toggleButton">
        <i class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('episode') }}
    </button>
</div>
<div class="col-md-12" id="add_card" style="display: none;">
    <div class="card card-secondary">
        <div class="card-header">
            <h3 class="card-title">{{ __('create') . ' ' . __('episode') }}</h3>
        </div>
        <div class="card-body">
            <form id="create_form" action="{{ url('podcast/episodes/store/' . $podcast->id) }}" role="form" method="POST"
                enctype="multipart/form-data">
                @csrf
                <div class="row">
                    <!-- Left Column -->
                    <div class="col-md-6 col-sm-12">
                        <div class="form-group">
                            <label class="required">{{ __('podcast') }}</label>
                            <input type="text" class="form-control" value="{{ $podcast->title }}" readonly>
                            <input type="hidden" name="podcast_id" value="{{ $podcast->id }}">
                        </div>

                        <div class="form-group">
                            <label class="required">{{ __('episode_no') }}</label>
                            <input id="episode_no" name="episode_no" required type="number"
                                placeholder="{{ __('episode_no') }}" class="form-control" min="1">
                            <small id="episode_error" class="text-danger d-none">
                                {{ __('This_episode_number_already_exists_for_this_podcast') }}
                            </small>
                        </div>
                        <div class="form-group">
                            <label class="required">{{ __('title') }}</label>
                            <input id="title" name="title" required type="text"
                                placeholder="{{ __('title') }}" class="form-control"
                                data-slug-table="podcast_episodes"
                                data-slug-target="#slug">
                        </div>
                        <div class="form-group">
                            <label class="required">{{ __('slug') }}</label><span
                                class="">({{ __('english_only') }})</span>
                            <input id="slug" name="slug" required type="text"
                                placeholder="{{ __('slug') }}" class="form-control">
                            <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                        </div>
                        <div class="form-group">
                            <label class="required">{{ __('source_type') }}</label>
                            <select name="source_type" id="source_type" class="form-control" required>
                                <option value="">{{ __('select') . ' ' . __('source_type') }}</option>
                                <option value="upload">{{ __('upload') }}</option>
                                <option value="youtube_link">{{ __('youtube_link') }}</option>
                            </select>
                        </div>
                        <div class="form-group audio_upload">
                            <label class="required">{{ __('audio_upload') }}</label>
                            <input name="audio_file" type="file" class="filepond" accept="audio/*" id="create_audio_file" required>
                            <div class="text-muted small mt-1">{{ __('supported_formats') }}: MP3, WAV, M4A, OGG | {{ __('max_size') }}: 20MB</div>
                            <div id="" class="text-danger mt-1" style="display:none;"></div>
                        </div>
                        <div class="form-group youtube_url_field">
                            <label class="required">{{ __('youtube_url') }}</label>
                            <input type="url" name="audio_url" class="form-control youtube_url" placeholder="https://youtube.com/watch?v=..." required>
                            <span class="error invalid-feedback youtube_url_error"></span>
                        </div>
                        <input type="hidden" name="duration_seconds" id="duration_seconds">
                        <div class="form-group">
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

                    <!-- Right Column -->
                    <div class="col-md-6 col-sm-12">
                        <div class="form-group clearfix">
                            <label class="required d-block">{{ __('image') }}</label>
                            <div class="filepond-wrapper">
                                <input name="image" type="file" class="filepond" accept="image/*" required>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="required">{{ __('published_date') }}</label>
                            <input id="published_date" name="published_date"
                                min="{{ date('Y-m-d') }}" type="date" class="form-control" value="{{ date('Y-m-d') }}">
                        </div>
                        <div class="form-group">
                            <label>{{ __('description') }}</label>
                            <textarea id="des" name="description" class="form-control" rows="5" placeholder="{{ __('enter_description') }}"
                                oninput="getWordCount('des','des_count','12.9px arial',0,0,'description')"></textarea>
                            <small id="des_count" class="form-text seo-hint text-muted" style="display:none"></small>
                        </div>
                        <div class="form-group">
                            <div class="form-check pl-0 form-switch d-flex align-items-center">
                                <label class="mr-2 mb-0">{{ __('want_to_save_as_draft') }}?</label>
                                <input type="hidden" name="is_draft" value="0">
                                <input class="form-check-input status-switch" type="checkbox" id="draft_switch" name="draft_switch">
                            </div>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-end">
                    <button type="submit" class="btn btn-primary ml-2">{{ __('submit') }}</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endcan