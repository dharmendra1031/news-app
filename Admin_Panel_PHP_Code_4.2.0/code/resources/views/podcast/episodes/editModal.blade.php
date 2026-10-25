@can('podcast-edit')
<div class="modal fade" id="editDataModal" tabindex="-1" role="dialog" aria-labelledby="editDataModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="editDataModalLabel">{{ __('edit') . ' ' . __('episode') }}</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <form id="update_form" action="{{ route('podcast.episodes.update') }}" role="form" method="POST" enctype="multipart/form-data">
                    @csrf
                    
                    <input type="hidden" name="podcast_id" id="edit_podcast_id">
                    <input type="hidden" name="episode_id" id="edit_episode_id">
                    <input type="hidden" name="edit_id" id="edit_id">
                    <div class="row">
                        <div class="col-md-6 col-sm-12">
                            <div class="form-group">
                                <label class="required">{{ __('episode_no') }}</label>
                                <input id="edit_episode_no" name="episode_no" required type="number"
                                    placeholder="{{ __('episode_no') }}" class="form-control" min="1">
                                    <small id="edit_episode_error" class="text-danger d-none">
                                        {{ __('This_episode_number_already_exists_for_this_podcast') }}
                                    </small>
                            </div>
                            <div class="form-group">
                                <label class="required">{{ __('title') }}</label>
                                <input id="edit_title" name="title" required type="text"
                                    placeholder="{{ __('title') }}" class="form-control"
                                    data-slug-table="podcast_episodes"
                                    data-slug-target="#edit_slug"
                                    data-slug-id="#edit_episode_id">
                            </div>
                            <div class="form-group">
                                <label class="required">{{ __('slug') }}</label>
                                <span>({{ __('english_only') }})</span>
                                <input id="edit_slug" name="slug" required type="text"
                                    placeholder="{{ __('slug') }}" class="form-control">
                                <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                            </div>
                            <div class="form-group">
                                <label class="required">{{ __('source_type') }}</label>
                                <select name="source_type" id="edit_source_type" class="form-control" required>
                                    <option value="">{{ __('select') . ' ' . __('source_type') }}</option>
                                    <option value="upload">{{ __('upload') }}</option>
                                    <option value="youtube_link">{{ __('youtube_link') }}</option>
                                </select>
                            </div>
                           <div class="form-group audio_upload">
                                <label class="required">{{ __('audio_upload') }}</label>
                                <input
                                    name="audio_file"
                                    type="file"
                                    class="filepond"
                                    accept="audio/*"
                                >
                                <div class="text-muted small mt-1">
                                    {{ __('supported_formats') }}: MP3, WAV, M4A, OGG
                                </div>
                                <div class="text-danger small mt-1" id="edit_audio_error"></div>
                                <!-- Audio Player -->
                                <div class="mt-3" id="audio_player_container" style="display: none;">
                                    <label class="d-block small text-muted">{{ __('current_audio') }}</label>
                                    <audio id="audio_player" controls style="width: 100%;">
                                        <source id="audio_source" type="audio/mpeg">
                                        Your browser does not support the audio element.
                                    </audio>
                                </div>
                            </div>
                            <div class="form-group youtube_url_field">
                                <label class="required">{{ __('youtube_url') }}</label>
                                <input type="url" name="audio_url" id="edit_audio_url" class="form-control youtube_url" placeholder="https://youtube.com/watch?v=...">
                                <span class="error invalid-feedback youtube_url_error"></span>
                            </div>
                            <input type="hidden" name="duration_seconds" id="edit_duration_seconds">
                            <div class="form-group">
                                <label>{{ __('status') }}</label><br>
                                <div id="edit_status1" class="btn-group">
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
                        <div class="col-md-6 col-sm-12">
                            <div class="form-group">
                                <label class="required">{{ __('image') }}</label>
                                <input name="image" type="file" class="filepond" accept="image/*">
                            </div>
                            <div class="form-group">
                                <label class="d-block small text-muted">{{ __('current_image') }}</label>
                                <img
                                    id="edit_image_preview"
                                    src=""
                                    alt="Current Image"
                                    class="img-thumbnail"
                                    style="max-height:100px; width:auto;"
                                >
                            </div>
                            <div class="form-group">
                                <label class="required">{{ __('published_date') }}</label>
                                <input id="edit_published_date" name="published_date"
                                     type="date" class="form-control" required>
                            </div>
                            <div class="form-group">
                                <label>{{ __('description') }}</label>
                                <textarea id="edit_description" name="description" class="form-control" rows="5" placeholder="{{ __('enter_description') }}"
                                    oninput="getWordCount('edit_description','edit_description_count','12.9px arial',0,0,'description')"></textarea>
                                <small id="edit_description_count" class="form-text seo-hint text-muted" style="display:none"></small>
                            </div>
                            <div class="form-group">
                                <div class="form-check pl-0 form-switch d-flex align-items-center">
                                    <label class="mr-2">{{ __('want_to_save_as_draft') }}?</label>
                                    <input type="hidden" name="is_draft" value="0">
                                    <input class="form-check-input edit-status-switch" type="checkbox" id="edit_draft_switch" name="edit_draft_switch">
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-default" data-dismiss="modal">{{ __('close') }}</button>
                        <button type="submit" class="btn btn-primary" id="update_episode_btn">{{ __('submit') }}</button>
                    </div>
                </form>
            </div>

        </div>
    </div>
</div>
@endcan
