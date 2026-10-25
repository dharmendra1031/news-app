<div class="modal fade" id="editDataModal">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('edit') . ' ' . __('e-news') }}</h4>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <form id="update_form" action="{{ url('e-news') }}" role="form" method="POST" enctype="multipart/form-data">
                @csrf
                <input type='hidden' name="edit_id" id="edit_id" value='' />
                <div class="modal-body">
                    <div class="row">
                        <div class="form-group col-md-6 col-sm-12">
                            <label class="required">{{ __('language') }}</label>
                            <select id="edit_language" name="language" class="form-control" required>
                                <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                @foreach ($languageList as $item)
                                    <option value="{{ $item->id }}">{{ $item->language }}
                                    </option>
                                @endforeach
                            </select>
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label class="required">{{ __('title') }}</label>
                            <input name="title" id="edit_title" required type="text" class="form-control"
                                data-slug-table="tbl_e_news"
                                data-slug-target="#edit_slug"
                                data-slug-id="#edit_id">
                        </div>
                    </div>
                    <div class="row">
                        <div class="form-group col-md-6 col-sm-12">
                            <label class="required">{{ __('slug') }}</label><span
                                class="">({{__('english_only')}})</span>
                            <input id="edit_slug" name="slug" value="{{ old('slug') }}" required type="text"
                                class="form-control">
                            <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label class="required">{{ __('date') }} </label>
                            <input id="edit_date" name="date" type="date" class="form-control" required>
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('meta_title') }}</label>
                            <input type="text" name="meta_title" class="form-control" id="edit_meta_title"
                                maxlength="70"
                                oninput="getWordCount('edit_meta_title','edit_meta_title_count','19.9px arial')"
                                placeholder="{{ __('meta_title_placeholder') }}">
                            <small class="form-text text-muted">{{ __('meta_title_hint') }}</small>
                            <small id="edit_meta_title_count" class="form-text seo-hint text-muted" style="display:none"></small>
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <x-schema-markup-field id="edit_schema_markup" />
                        </div>
                    </div>
                    <div class="row">

                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('meta_keywords') }}</label>
                            <input id="edit_meta_tags" style="border-radius: 0.25rem" class="w-100" type="text"
                                name="meta_keyword" placeholder="{{ __('press_enter_add_keywords') }}">
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('meta_description') }}</label>
                            <textarea id="edit_meta_description" name="meta_description" class="form-control" rows="3"
                                maxlength="170"
                                oninput="getWordCount('edit_meta_description','edit_meta_description_count','12.9px arial')"
                                placeholder="{{ __('meta_description_placeholder') }}"></textarea>
                            <small class="form-text text-muted">{{ __('meta_description_hint') }}</small>
                            <small id="edit_meta_description_count" class="form-text seo-hint text-muted" style="display:none"></small>
                        </div>
                    </div>
                    <div class="row">
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('thumbnail') }} </label>
                            <input name="thumbnail" type="file" class="filepond">
                             <div id="edit_image_preview_container" class="mt-2" >
                                  <label class="d-block small text-muted">{{ __('current_thumbnail') }}</label>
                                   <img id="edit_image_preview" src="" alt="Current Image" class="img-thumbnail" style="max-height: 100px;">
                             </div>
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('attachment (PDF)') }} </label> <a id="filepreview" href="" target="_blank">{{ __('preview_current_file') }}</a>
                            <input name="attachment" type="file" class="filepond-pdf" accept="application/pdf">

                        </div>
                    </div>
                    <div class="row">
                        <div class="form-group col-md-12 col-sm-12">
                            <label>{{ __('description') }}</label>
                            <textarea id="edit_des" name="description" class="form-control"></textarea>
                            <small id="edit_des_count" class="form-text seo-hint text-muted" style="display:none"></small>
                        </div>
                    </div>
                    <div class="row">
                        <div class="form-group col-md-3 col-sm-12">
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
                            {{-- <div class="form-check form-switch d-flex align-items-center p-0">
                                <label class="mr-2">{{ __('status') }}</label>
                                <input type="hidden" id="edit_status" name="status" value="0">
                                <input class="form-check-input me-2 status-switch" type="checkbox"
                                    id="edit_status_switch" name="edit_status_switch">
                            </div> --}}
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
