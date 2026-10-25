@extends ('layouts.main')
@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('alerts') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ 'system-settings' }}" class="text-dark"><i class="nav-icon fas fa-cogs mr-1"></i>{{ __('system_setting') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-bell mr-1"></i>{{ __('alerts') }}
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    
    <section class="content">
        <div class="container-fluid">
            @can('alerts-create')
            @include('alerts.create')
            @endcan 
            <div class="row">
                @can('alerts-list')
                    <div class="col-md-12">
                        <div class="card card-secondary">
                            <div class="card-header">
                                <h3 class="card-title">{{ __('alerts') . ' ' . __('list') }}</h3>
                            </div>
                            <div class="card-body">
                                <table aria-describedby="mydesc" id='table' data-toggle="table"
                                    data-url="{{ route('alerts.show',1  ) }}" data-click-to-select="true"
                                    data-side-pagination="server" data-pagination="true" data-page-list="[5, 10, 20, 50, 100, 200]"
                                    data-search="true" data-show-columns="true"
                                    data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true"
                                    data-buttons-class="primary" data-trim-on-search="false" data-sort-name="id" data-sort-order="desc"
                                    data-query-params="alertsParams">
                                    <thead>
                                        <tr>
                                            @can('alerts-bulk-delete')
                                                <th class="text-center multi-check" data-checkbox="true"></th>
                                            @endcan
                                            <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                            <th scope="col" data-field="alert_type">{{ __('alert_type') }}</th>
                                            <th scope="col" data-field="name" >{{ __('name') }}</th>
                                            <th scope="col" data-field="exchange" >{{ __('exchange') }}</th>
                                            <th scope="col" data-field="current_price" data-sortable="true">{{ __('current_price') }}</th>
                                            <th scope="col" data-field="percent_change" data-sortable="true">{{ __('percent_change') }}</th>
                                            <th scope="col" data-field="currency">{{ __('currency') }}</th>
                                            <th scope="col" data-field="direction" data-sortable="true">{{ __('direction') }}</th>
                                            <th scope="col" data-field="status" data-formatter="alertStatusFormatter">{{ __('status') }}</th>
                                            <th scope="col" data-field="created_at" data-visible="false">{{ __('created_at') }}</th>
                                            @canany(['alerts-edit', 'alerts-delete'])
                                                <th scope="col" data-field="operate" data-events="alertsEvents">
                                                    {{ __('operate') }}</th>
                                            @endcanany
                                        </tr>
                                    </thead>
                                </table>
                            </div>
                        </div>
                    </div>
                @endcan
            </div>
        </div>
    </section>
    @can('alerts-edit')
        @include('alerts.editModal')
    @endcan
@endsection
@section('script')
<script>
    function alertsParams(params) {
        return params;
    }

    $(document).ready(function () {
        let searchTimeout;

        $('#toggleButton').on('click', function () {
            $('#add_card').show();
        });

        function resetNameSearch() {
            $('#namesearch').val('');
            $('#search-results').hide().empty();
        }

        function resetSelection() {
            $('#selected_symbol').val('');
            $('#selected_name').val('');
            $('#selected_exchange').val('');
            $('#selected_ipo_price').val('');
        }

        function resetForexCommodity() {
            $('#forex_select').val('');
            $('#commodity_select').val('');
            $('#crypto_select').val('');
            $('#ipo_select').val('');
        }

        $('#alert_type').on('change', function () {
            const type = $(this).val();

            resetNameSearch();
            resetSelection();
            resetForexCommodity();
            $('#namesearch_group, #forex_group, #commodity_group, #crypto_group, #ipo_group').hide();

            if (type === 'stock') {
                $('#namesearch_group').show();
            } else if (type === 'forex') {
                $('#forex_group').show();
            } else if (type === 'commodity') {
                $('#commodity_group').show();
            } else if (type === 'Crypto') {
                $('#crypto_group').show();
            } else if (type === 'IPO') {
                $('#ipo_group').show();
            }
        });

        $('#namesearch').on('input', function () {
            clearTimeout(searchTimeout);
            const query = $(this).val().trim();

            // Clear the hidden fields any time the visible text changes,
            // so a stale selection can't be submitted after the user edits it.
            resetSelection();

            if (query.length < 2) {
                $('#search-results').hide().empty();
                return;
            }

            searchTimeout = setTimeout(function () {
                $.ajax({
                    url: '{{ route("alerts.search", "") }}/' + encodeURIComponent(query),
                    method: 'GET',
                    dataType: 'json',
                    data: { type: $('#alert_type').val() },
                    success: function (data) {
                        const $results = $('#search-results');
                        $results.empty().show();

                        if (data.length === 0) {
                            $results.append('<a class="list-group-item list-group-item-action disabled">{{ __("no_results_found") }}</a>');
                            return;
                        }

                        $.each(data, function (index, item) {
                            const displayText = item.name + ' (' + item.symbol + ') - ' + item.exchange;
                            const $item = $('<a class="list-group-item list-group-item-action" href="#"></a>')
                                .html('<strong>' + item.symbol + '</strong> - ' + item.name + ' <small class="text-muted">(' + item.exchange + ')</small>')
                                .on('click', function (e) {
                                    e.preventDefault();
                                    $('#namesearch').val(displayText);
                                    $('#selected_symbol').val(item.symbol);
                                    $('#selected_name').val(item.name);
                                    $('#selected_exchange').val(item.exchange);
                                    $results.hide().empty();
                                });
                            $results.append($item);
                        });
                    },
                    error: function () {
                        $('#search-results').hide().empty();
                    }
                });
            }, 300);
        });

        $('#forex_select, #commodity_select').on('change', function () {
            const $opt = $(this).find('option:selected');
            $('#selected_symbol').val($(this).val());
            $('#selected_name').val($opt.data('name') || '');
            $('#selected_exchange').val('OANDA');
        });

        $('#crypto_select').on('change', function () {
            const $opt = $(this).find('option:selected');
            $('#selected_symbol').val($(this).val());
            $('#selected_name').val($opt.data('name') || '');
            $('#selected_exchange').val('Binance');
        });

        $('#ipo_select').on('change', function () {
            const $opt = $(this).find('option:selected');
            $('#selected_symbol').val($(this).val());
            $('#selected_name').val($opt.data('name') || '');
            $('#selected_exchange').val($opt.data('exchange') || '');
            $('#selected_ipo_price').val($opt.data('price') || '');
        });

        $(document).on('click', function (e) {
            if (!$(e.target).closest('#namesearch, #search-results').length) {
                $('#search-results').hide().empty();
            }
        });

        function submitAlertForm($form, $btn, onSuccess) {
            $btn.prop('disabled', true);

            $.ajax({
                url: $form.attr('action'),
                type: 'POST',
                data: $form.serialize(),
                success: function (response) {
                    if (response.error === false) {
                        showSuccessToast(response.message);
                        onSuccess();
                        $('#table').bootstrapTable('refresh');
                    } else {
                        showErrorToast(response.message);
                    }
                },
                error: function (xhr) {
                    let message = (xhr.responseJSON && xhr.responseJSON.message) || '{{ __('something_went_wrong') }}';
                    if (xhr.responseJSON && xhr.responseJSON.errors) {
                        message = Object.values(xhr.responseJSON.errors).flat().join('<br>');
                    }
                    showErrorToast(message);
                },
                complete: function () {
                    $btn.prop('disabled', false);
                }
            });
        }

        $('#alert_create_form').on('submit', function (e) {
            e.preventDefault();

            $('.error-text').text('');

            const type = $('#alert_type').val();
            if (['stock', 'forex', 'commodity', 'Crypto', 'IPO'].includes(type) && (!$('#selected_symbol').val() || !$('#selected_name').val())) {
                $('#symbol_error').text('{{ __("please_select_a_result_from_the_search_list") }}');
                return;
            }

            submitAlertForm($(this), $('#alert_create_submit_btn'), function () {
                $('#alert_create_form')[0].reset();
                resetNameSearch();
                resetSelection();
                resetForexCommodity();
                $('#namesearch_group, #forex_group, #commodity_group, #crypto_group, #ipo_group').hide();
                $('#add_card').hide();
            });
        });

        // Update form submission handler
        // $('#update_form').on('submit', function (e) {
        //     e.preventDefault();

        //     const type = $('#edit_alert_type').val();
        //     if (['stock', 'forex', 'commodity', 'Crypto', 'IPO'].includes(type) && (!$('#edit_selected_symbol').val() || !$('#edit_selected_name').val())) {
        //         return;
        //     }

        //     submitAlertForm($(this), $('#update_submit_btn'), function () {
        //         $('#editDataModal').modal('hide');
        //     });
        // });


        // Edit modal search functionality
        $('#edit_alert_type').on('change', function() {
            const type = $(this).val();

            $('#edit_namesearch').val('');
            $('#edit_selected_symbol').val('');
            $('#edit_selected_name').val('');
            $('#edit_selected_exchange').val('');
            $('#edit_selected_ipo_price').val('');
            $('#edit_forex_select').val('');
            $('#edit_commodity_select').val('');
            $('#edit_crypto_select').val('');
            $('#edit_ipo_select').val('');
            $('#edit_search-results').hide().empty();
            $('#edit_namesearch_group, #edit_forex_group, #edit_commodity_group, #edit_crypto_group, #edit_ipo_group').hide();

            if (type === 'stock') {
                $('#edit_namesearch_group').show();
            } else if (type === 'forex') {
                $('#edit_forex_group').show();
            } else if (type === 'commodity') {
                $('#edit_commodity_group').show();
            } else if (type === 'Crypto') {
                $('#edit_crypto_group').show();
            } else if (type === 'IPO') {
                $('#edit_ipo_group').show();
            }
        });

        $('#edit_namesearch').on('input', function() {
            clearTimeout(searchTimeout);
            const query = $(this).val().trim();

            $('#edit_selected_symbol').val('');
            $('#edit_selected_name').val('');
            $('#edit_selected_exchange').val('');

            if (query.length < 2) {
                $('#edit_search-results').hide().empty();
                return;
            }

            searchTimeout = setTimeout(function() {
                $.ajax({
                    url: '{{ route("alerts.search", "") }}/' + encodeURIComponent(query),
                    method: 'GET',
                    dataType: 'json',
                    data: { type: $('#edit_alert_type').val() },
                    success: function(data) {
                        const $results = $('#edit_search-results');
                        $results.empty().show();

                        if (data.length === 0) {
                            $results.append('<a class="list-group-item list-group-item-action disabled">{{ __("no_results_found") }}</a>');
                            return;
                        }

                        $.each(data, function(index, item) {
                            const displayText = item.name + ' (' + item.symbol + ') - ' + item.exchange;
                            const $item = $('<a class="list-group-item list-group-item-action" href="#"></a>')
                                .html('<strong>' + item.symbol + '</strong> - ' + item.name + ' <small class="text-muted">(' + item.exchange + ')</small>')
                                .on('click', function(e) {
                                    e.preventDefault();
                                    $('#edit_namesearch').val(displayText);
                                    $('#edit_selected_symbol').val(item.symbol);
                                    $('#edit_selected_name').val(item.name);
                                    $('#edit_selected_exchange').val(item.exchange);
                                    $('#edit_search-results').hide().empty();
                                });
                            $results.append($item);
                        });
                    },
                    error: function() {
                        $('#edit_search-results').hide().empty();
                    }
                });
            }, 300);
        });

        $('#edit_forex_select, #edit_commodity_select').on('change', function () {
            const $opt = $(this).find('option:selected');
            $('#edit_selected_symbol').val($(this).val());
            $('#edit_selected_name').val($opt.data('name') || '');
            $('#edit_selected_exchange').val('OANDA');
        });

        $('#edit_crypto_select').on('change', function () {
            const $opt = $(this).find('option:selected');
            $('#edit_selected_symbol').val($(this).val());
            $('#edit_selected_name').val($opt.data('name') || '');
            $('#edit_selected_exchange').val('Binance');
        });

        $('#edit_ipo_select').on('change', function () {
            const $opt = $(this).find('option:selected');
            $('#edit_selected_symbol').val($(this).val());
            $('#edit_selected_name').val($opt.data('name') || '');
            $('#edit_selected_exchange').val($opt.data('exchange') || '');
            $('#edit_selected_ipo_price').val($opt.data('price') || '');
        });

        $(document).on('click', function(e) {
            if (!$(this).closest('#edit_namesearch, #edit_search-results').length) {
                $('#edit_search-results').hide().empty();
            }
        });
    });
</script>

@endsection
