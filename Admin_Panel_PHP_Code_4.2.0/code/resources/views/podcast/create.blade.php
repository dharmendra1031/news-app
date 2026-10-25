<div class="col-md-12" id="add_card">
        <div class="card card-secondary">
            <div class="card-header">
                <h3 class="card-title">{{ __('create') . ' ' . __('podcast') }}</h3>
            </div>
            <div class="card-body">
                <form id="create_form" action="{{ route('podcast.store') }}" role="form" method="POST"
                    enctype="multipart/form-data">
                    @csrf
                    <div class="row">
                        <div class="form-group col-md-6 col-sm-12">
                            <label class="required">{{ __('title') }}</label>
                            <input id="title" name="title" required type="text"
                                placeholder="{{ __('title') }}" class="form-control" data-slug-table="podcasts"
                                data-slug-target="#slug">
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label class="required">{{ __('slug') }}</label><span
                                class="">({{ __('english_only') }})</span>
                            <input id="slug" name="slug" required type="text"
                                placeholder="{{ __('slug') }}" class="form-control">
                            <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                        </div>
                    </div>
                    <div class="row">
                        <div class="form-group col-md-6 col-sm-12">
                            <x-schema-markup-field />
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('meta_keywords') }}</label>
                            <input id="meta_tags" style="border-radius: 0.25rem" class="w-100" type="text"
                                name="meta_keyword" placeholder="{{ __('press_enter_add_keywords') }}">
                        </div>
                    </div>
                    <div class="row">
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('meta_title') }}</label>
                            <input type="text" name="meta_title" class="form-control" id="meta_title"
                                oninput="getWordCount('meta_title','meta_title_count','19.9px arial')"
                                placeholder="{{ __('meta_title') }}">
                            <h6 id="meta_title_count">0</h6>
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('meta_description') }}</label>
                            <textarea id="meta_description" name="meta_description" class="form-control"
                                oninput="getWordCount('meta_description','meta_description_count','12.9px arial')"></textarea>
                            <h6 id="meta_description_count">0</h6>
                        </div>
                    </div>
                    <div class="row">
                        <div class="form-group col-md-6 col-sm-12">
                            <label>{{ __('date') }}</label>
                            <input id="published_date" name="published_date"
                                min="{{ date('Y-m-d') }}" type="date" class="form-control" value="{{ date('Y-m-d') }}">
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
                            <label class="required">{{ __('description') }}</label>
                            <textarea id="des" name="des" class="form-control required"
                                oninput="getWordCount('des','des_count','12.9px arial',0,0,'description')"></textarea>
                            <small id="des_count" class="form-text seo-hint text-muted" style="display:none"></small>
                        </div>
                        <div class="form-group col-md-6 col-sm-12">
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
                        <div class="form-group col-md-6 col-sm-12">
                            <div class="form-check pl-0 form-switch d-flex align-items-center">
                                <label class="mr-2">{{ __('want_to_save_as_draft') }}?</label>
                                <input type="hidden" name="is_draft" value="0">
                                <input class="form-check-input status-switch" type="checkbox" id="draft_switch" name="draft_switch">
                            </div>
                        </div>
                    </div>
                    <div class="form-group col-md-6 col-sm-12 image_upload">
                        <label class="required"for="image">{{ __('image') }}</label>
                        <input name="image" type="file" class="filepond" id="create_image" accept="image/*" required>
                        <div id="create_image_error" class="text-danger mt-1" style="display:none;"></div>
                    </div>
                    <div class="d-flex justify-content-end">
                        <button type="submit" class="btn btn-primary ml-2">{{ __('submit') }}</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

