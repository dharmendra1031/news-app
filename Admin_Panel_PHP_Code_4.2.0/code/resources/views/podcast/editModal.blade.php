@can('podcast-edit')
<div class="modal fade" id="editDataModal" tabindex="-1" role="dialog" aria-labelledby="editDataModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-xl" >
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="editDataModalLabel">{{ __('edit') . ' ' . __('podcast') }}</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                    <form id="update_form" action="{{ url('podcast') }}"  method="POST" enctype="multipart/form-data">
                    @csrf
                     <input type='hidden' name="edit_id" id="edit_id" value='' />
                    <div class="row">
                        <div class="form-group col-md-6 col-sm-12">
                            <label class="required">{{ __('title') }}</label>
                            <input id="edit_title" name="title" required type="text"
                                placeholder="{{ __('title') }}"
                                class="form-control"
                                data-slug-table="podcasts"
                                data-slug-target="#edit_slug">
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label class="required">{{ __('slug') }}</label>
                            <span>({{ __('english_only') }})</span>
                            <input id="edit_slug" name="slug" required type="text"
                                placeholder="{{ __('slug') }}" class="form-control">
                            <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                        </div>
                    </div>
                    <div class="row">
                        <div class="form-group col-md-6 col-sm-12">
                            <x-schema-markup-field id="edit_schema_markup" />
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('meta_keywords') }}</label>
                            <input id="edit_meta_tags" style="border-radius: 0.25rem" class="w-100" type="text"
                                name="meta_keyword" placeholder="{{ __('press_enter_add_keywords') }}">
                        </div>
                    </div>
                    <div class="row">
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('meta_title') }}</label>
                            <input type="text" name="meta_title" class="form-control" id="edit_meta_title"
                                oninput="getWordCount('edit_meta_title','edit_meta_title_count','19.9px arial')"
                                placeholder="{{ __('meta_title') }}">
                            <h6 id="edit_meta_title_count">0</h6>
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('meta_description') }}</label>
                            <textarea id="edit_meta_description" name="meta_description" class="form-control"
                                oninput="getWordCount('edit_meta_description','edit_meta_description_count','12.9px arial')"></textarea>
                            <h6 id="edit_meta_description_count">0</h6>
                        </div>
                    </div>
                    <div class="row">
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('date') }}</label>
                            <input id="edit_published_date"
                                name="published_date"
                                type="date"
                                class="form-control">
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label class="required">{{ __('description') }}</label>
                            <textarea id="edit_des" name="des" class="form-control required"
                                oninput="getWordCount('edit_des','edit_des_count','12.9px arial',0,0,'description')"></textarea>
                            <small id="edit_des_count" class="form-text seo-hint text-muted" style="display:none"></small>
                        </div>

                    </div>
                    <div class="form-group col-md-12 col-sm-12 image_upload">
                        <label class="required">{{ __('image') }}</label>

                        <div class="row align-items-start">
                            <!-- FilePond -->
                            <div class="col-md-6">
                                <input
                                    name="image"
                                    type="file"
                                    class="filepond"
                                    id="edit_image"
                                    accept="image/*"
                                >
                                <div id="edit_image_error" class="text-danger mt-1" style="display:none;"></div>
                            </div>
  
                            <!-- Image Preview -->
                            <div class="col-md-6">
                                <div class="form-check pl-0 form-switch d-flex align-items-center">
                                <label class="mr-2">{{ __('want_to_save_as_draft') }}?</label>
                                <input type="hidden" name="is_draft" value="0">
                                <input
                                    class="form-check-input status-switch"
                                    type="checkbox"
                                    id="edit_draft_switch"
                                    name="draft_switch">
                            </div>
                      
                            </div>
                        </div>
                    </div>
                    <div class="row">
                        <div class="form-group col-md-6 col-sm-12">
                               <label class="d-block small text-muted">{{ __('current_image') }}</label>
                                <img
                                    id="edit_image_preview"
                                    src=""
                                    alt="Current Image"
                                    class="img-thumbnail"
                                    style="max-height:100px; width:auto;"
                                >
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('status') }}</label><br>
                            <div id="edit_status1" class="btn-group">
                                <label class="btn btn-success">
                                    <input type="radio" name="status" value="1">
                                    {{ __('active') }}
                                </label>
                                <label class="btn btn-danger">
                                    <input type="radio" name="status" value="0">
                                    {{ __('deactive') }}
                                </label>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-default" data-dismiss="modal">{{ __('close') }}</button>
                        <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                    </div>
                </form>
            </div>

        </div>
    </div>
</div>
@endcan
