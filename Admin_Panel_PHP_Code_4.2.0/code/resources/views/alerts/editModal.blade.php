<div class="modal fade" id="editDataModal">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('edit') . ' ' . __('alerts') }}</h4>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <form id="update_form" action="{{ url('alerts') }}" role="form" method="POST" enctype="multipart/form-data">
                @csrf
                <input type='hidden' name="edit_id" id="edit_id" value='' />
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6 col-sm-12">
                            <div class="form-group">
                                <label class="required">{{__('alert')." ". __('type') }}</label>
                                <select name="alert_type" id="edit_alert_type" class="form-control" required>
                                    <option value="">{{__('select')." ".__('alert')." ". __('type') }}</option>
                                    @foreach ($alertTypeOptions as $option)
                                        <option value="{{ $option['value'] }}" @disabled($option['pending'])>
                                            {{ $option['label'] }}{{ $option['pending'] ? ' (' . __('coming_soon') . ')' : '' }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="form-group" id="edit_namesearch_group" style="display: none;">
                                <label class="required">{{ __('namesearch') }}</label>
                                <input  id="edit_namesearch" class="form-control" autocomplete="off">
                                <div id="edit_search-results" class="list-group" style="position: absolute; z-index: 1000; width: 100%; display: none;"></div>
                            </div>
                            <div class="form-group" id="edit_forex_group" style="display: none;">
                                <label class="required">{{ __('forex') }}</label>
                                <select id="edit_forex_select" class="form-control">
                                    <option value="">{{__('select')." ".__('forex') }}</option>
                                    @foreach ($forexOptions as $label => $symbol)
                                        <option value="{{ $symbol }}" data-name="{{ $label }}">{{ $label }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="form-group" id="edit_commodity_group" style="display: none;">
                                <label class="required">{{ __('commodity') }}</label>
                                <select id="edit_commodity_select" class="form-control">
                                    <option value="">{{__('select')." ".__('commodity') }}</option>
                                    @foreach ($commodityOptions as $label => $symbol)
                                        <option value="{{ $symbol }}" data-name="{{ $label }}">{{ $label }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="form-group" id="edit_crypto_group" style="display: none;">
                                <label class="required">{{ __('crypto') }}</label>
                                <select id="edit_crypto_select" class="form-control">
                                    <option value="">{{__('select')." ".__('crypto') }}</option>
                                    @foreach ($cryptoOptions as $label => $symbol)
                                        <option value="{{ $symbol }}" data-name="{{ $label }}">{{ $label }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="form-group" id="edit_ipo_group" style="display: none;">
                                <label class="required">{{ __('ipo') }}</label>
                                <select id="edit_ipo_select" class="form-control">
                                    <option value="">{{__('select')." ".__('ipo') }}</option>
                                    @foreach ($ipoOptions as $option)
                                        <option value="{{ $option['symbol'] }}" data-name="{{ $option['name'] }}" data-exchange="{{ $option['exchange'] }}" data-price="{{ $option['price'] }}">
                                            {{ $option['name'] }} ({{ $option['symbol'] }}) - {{ $option['date'] }}{{ $option['price'] ? ' @ ' . $option['price'] : '' }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>
                            <input  name="symbol" id="edit_selected_symbol" type="hidden">
                            <input  name="name" id="edit_selected_name" type="hidden">
                            <input  name="exchange" id="edit_selected_exchange" type="hidden">
                            <input  name="ipo_price" id="edit_selected_ipo_price" type="hidden">
                        </div>
                        <div class="col-md-6 col-sm-12">
                            <div class="form-group">
                                <label>{{ __('status') }}</label><br>
                                <div id="status1" class="btn-group">
                                    <label class="btn btn-success" data-toggle-class="btn-primary"
                                        data-toggle-passive-class="btn-default">
                                        <input type="radio" name="status" id="edit_status" value="1" class="edit-status-radio" checked>{{ __('active') }}
                                    </label>
                                    <label class="btn btn-danger" data-toggle-class="btn-primary"
                                        data-toggle-passive-class="btn-default">
                                        <input type="radio" name="status" value="0" class="edit-status-radio">{{ __('deactive') }}
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal">{{ __('close') }}</button>
                    <button type="submit" id="update_submit_btn" class="btn btn-primary">{{ __('submit') }}</button>
                </div>
            </form>
        </div>
    </div>
</div>
