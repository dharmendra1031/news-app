<div class="row">
    <div class="col-md-12 d-flex justify-content-end">
        <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i
                class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('alerts') }}</button>
    </div>
</div>
<div class="row">
    <div class="col-md-12" id="add_card">
        <div class="card card-secondary">
            <div class="card-header">
                <h3 class="card-title">{{ __('create') . ' ' . __('alerts') }}</h3>
            </div>
            <div class="card-body">
                @if (!$twelvedataConfigured || !$finnhubConfigured)
                    <div class="alert alert-warning" id="alerts_api_key_note">
                        <i
                            class="fas fa-exclamation-triangle mr-1"></i>{{ __('please_configure_twelvedata_and_finnhub_api_keys_note') }}
                        <a href="{{ route('general-settings') }}">{{ __('general_setting') }}</a>
                    </div>
                @endif
                <form id="alert_create_form" action="{{ route('alerts.store') }}" role="form" method="POST"
                    enctype="multipart/form-data">
                    @csrf
                    <div class="row">
                        <div class="col-md-6 col-sm-12">
                            <div class="form-group">
                                <label class="required">{{ __('alert') . ' ' . __('type') }}</label>
                                <select name="alert_type" id="alert_type" class="form-control" required>
                                    <option value="">{{ __('select') . ' ' . __('alert') . ' ' . __('type') }}</option>
                                    @foreach ($alertTypeOptions as $option)
                                        <option value="{{ $option['value'] }}" @disabled($option['pending'])>
                                            {{ $option['label'] }}{{ $option['pending'] ? ' (' . __('coming_soon') . ')' : '' }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="form-group" id="namesearch_group" style="display: none;">
                                <label class="required">{{ __('namesearch') }}</label>
                                <input type="text" id="namesearch" class="form-control">
                                <div id="search-results" class="list-group"
                                    style="position: absolute; z-index: 1000; width: 100%; display: none;"></div>
                            </div>
                            <div class="form-group" id="forex_group" style="display: none;">
                                <label class="required">{{ __('forex') }}</label>
                                <select id="forex_select" class="form-control">
                                    <option value="">{{ __('select') . ' ' . __('forex') }}</option>
                                    @foreach ($forexOptions as $label => $symbol)
                                        <option value="{{ $symbol }}" data-name="{{ $label }}">
                                            {{ $label }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="form-group" id="commodity_group" style="display: none;">
                                <label class="required">{{ __('commodity') }}</label>
                                <select id="commodity_select" class="form-control">
                                    <option value="">{{ __('select') . ' ' . __('commodity') }}</option>
                                    @foreach ($commodityOptions as $label => $symbol)
                                        <option value="{{ $symbol }}" data-name="{{ $label }}">
                                            {{ $label }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="form-group" id="crypto_group" style="display: none;">
                                <label class="required">{{ __('crypto') }}</label>
                                <select id="crypto_select" class="form-control">
                                    <option value="">{{ __('select') . ' ' . __('crypto') }}</option>
                                    @foreach ($cryptoOptions as $label => $symbol)
                                        <option value="{{ $symbol }}" data-name="{{ $label }}">
                                            {{ $label }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="form-group" id="ipo_group" style="display: none;">
                                <label class="required">{{ __('ipo') }}</label>
                                <select id="ipo_select" class="form-control">
                                    <option value="">{{ __('select') . ' ' . __('ipo') }}</option>
                                    @foreach ($ipoOptions as $option)
                                        <option value="{{ $option['symbol'] }}" data-name="{{ $option['name'] }}"
                                            data-exchange="{{ $option['exchange'] }}"
                                            data-price="{{ $option['price'] }}">
                                            {{ $option['name'] }} ({{ $option['symbol'] }}) -
                                            {{ $option['date'] }}{{ $option['price'] ? ' @ ' . $option['price'] : '' }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>
                            <input type="hidden" name="symbol" id="selected_symbol">
                            <input type="hidden" name="name" id="selected_name">
                            <input type="hidden" name="exchange" id="selected_exchange">
                            <input type="hidden" name="ipo_price" id="selected_ipo_price">
                            <div class="error-text text-danger" id="symbol_error"></div>
                        </div>
                        <div class="col-md-6 col-sm-12">
                            <div class="form-group">
                                <label>{{ __('status') }}</label><br>
                                <div id="status1" class="btn-group">
                                    <label class="btn btn-success" data-toggle-class="btn-primary"
                                        data-toggle-passive-class="btn-default">
                                        <input type="radio" name="status" value="1"
                                            checked>{{ __('active') }}
                                    </label>
                                    <label class="btn btn-danger" data-toggle-class="btn-primary"
                                        data-toggle-passive-class="btn-default">
                                        <input type="radio" name="status" value="0">{{ __('deactive') }}
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="d-flex justify-content-end">
                        <button type="submit" id="alert_create_submit_btn"
                            class="btn btn-primary ml-2">{{ __('submit') }}</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
