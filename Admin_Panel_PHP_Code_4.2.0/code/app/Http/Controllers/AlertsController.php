<?php

namespace App\Http\Controllers;

use App\Models\Alerts;
use App\Services\FinnhubService;
use App\Services\TwelveDataService;
use App\Services\ResponseService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Throwable;

class AlertsController extends Controller
{
    protected TwelveDataService $twelveDataService;
    protected FinnhubService $finnhubService;

    public function __construct(TwelveDataService $twelveDataService, FinnhubService $finnhubService)
    {
        $this->twelveDataService = $twelveDataService;
        $this->finnhubService = $finnhubService;
    }

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect([
            'alerts-list',
            'alerts-create',
            'alerts-edit',
            'alerts-delete',
        ]);

        $twelvedataConfigured = filled(getSettingMode('twelvedata_api_key'));
        $finnhubConfigured    = filled(getSettingMode('finnhub_api_key'));

        $ipoOptions = [];
        if ($finnhubConfigured) {
            try {
                $ipoOptions = $this->finnhubService->ipoCalendar();
            } catch (Throwable $e) {
                report($e);
            }
        }

        return view('alerts.index', [
            'alertTypeOptions'     => $this->twelveDataService->alertTypeOptions(),
            'forexOptions'         => $this->twelveDataService->forexOptions(),
            'commodityOptions'     => $this->twelveDataService->commodityOptions(),
            'cryptoOptions'        => $this->twelveDataService->cryptoOptions(),
            'ipoOptions'           => $ipoOptions,
            'twelvedataConfigured' => $twelvedataConfigured,
            'finnhubConfigured'    => $finnhubConfigured,
        ]);
    }

    /**
     * Search for company name and symbol via Finnhub. Stock only - forex/commodity
     * use the curated dropdowns instead (see TwelveDataService::forexOptions/commodityOptions).
     */
    public function searchCompany(string $query, Request $request)
    {
        if ($request->input('type') !== 'stock') {
            return response()->json([]);
        }

        $formatted = array_map(function ($result) {
            return [
                'symbol'   => $result['symbol'],
                'name'     => $result['name'],
                'exchange' => $result['exchange'],
                'type'     => 'stock',
            ];
        }, $this->twelveDataService->search($query));

        return response()->json($formatted);
    }

    /**
     * Datatable JSON feed for the listing.
     */
    public function show(Request $request)
    {
        $offset = $request->input('offset', 0);
        $limit  = $request->input('limit', 10);
        $sort   = $request->input('sort', 'id');
        $order  = $request->input('order', 'DESC');
        $search = $request->input('search');

        $query = Alerts::query();

        // Search
        if (!empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%$search%")
                    ->orWhere('symbol', 'LIKE', "%$search%")
                    ->orWhere('exchange', 'LIKE', "%$search%");
            });
        }

        // Filters
        if ($request->filled('alert_type')) {
            $query->where('alert_type', $request->alert_type);
        }

        if ($request->status !== null && $request->status !== '') {
            $query->where('status', $request->status);
        }

        $total = $query->count();

        $rows = $query->orderBy($sort, $order)
            ->skip($offset)
            ->take($limit)
            ->get();

        $rows->transform(function ($row) {

            $edit = '';
            if (auth()->user()->can('alerts-edit')) {
                $edit = '<a href="javascript:void(0)" class="dropdown-item alerts-edit" data-id="' . $row->id . '" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }
            $delete = '';
            if (auth()->user()->can('alerts-delete')) {
                $delete = '<a data-url="' . route('alerts.destroy', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
            }
            $operate = '';
            if ($edit == '' && $delete == '') {
                $operate = '-';
            } else {
                $operate =
                    '<div class="dropdown">
                            <a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" data-boundary="window" data-container="body">
                                <button class="btn btn-primary btn-sm px-3 operatebtn"><i class="fas fa-ellipsis-v"></i></button>
                            </a>
                            <div class="dropdown-menu dropdown-scrollbar" aria-labelledby="dropdownMenuButton">
                            ' .
                    $edit .
                    $delete .
                    '
                            </div>
                        </div>';
            }

            return [
                'id'              => $row->id,
                'alert_type'      => $row->alert_type,
                'name'            => $row->name,
                'symbol'          => $row->symbol,
                'exchange'        => $row->exchange,
                'ipo_price'       => $row->ipo_price,
                'current_price'   => $row->current_price,
                'currency'        => $row->currency,
                'percent_change'  => $row->percent_change,
                'direction'       => $row->direction,
                'status'          => $row->status,
                'last_updated_at' => $row->last_updated_at,
                'operate'         => $operate,
            ];
        });

        return response()->json([
            'total' => $total,
            'rows'  => $rows,
        ]);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {

    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'alert_type' => 'required|in:stock,commodity,forex,Crypto,IPO',
            'symbol'     => 'required|string|max:50',
            'name'       => 'required|string|max:255',
            'exchange'   => 'nullable|string|max:50',
            'ipo_price'  => 'nullable|string|max:50',
            'status'     => 'required|boolean',
        ]);

        if (in_array($request->alert_type, TwelveDataService::PENDING_TYPES, true)) {
            return ResponseService::errorResponse(__(':type_alerts_are_coming_soon', ['type' => $request->alert_type]));
        }

        if ($this->twelveDataService->hasAlertOfType($request->alert_type)) {
            return ResponseService::errorResponse(__('an_active_:type_alert_already_exists_delete_it_before_adding_a_new_one', ['type' => $request->alert_type]));
        }


        // apikey validation
        if ($request->alert_type !== 'IPO' && !filled(getSettingMode('twelvedata_api_key'))) {
            return ResponseService::errorResponse(__('please_configure_your_twelvedata_api_key_in_settings'));
        }
        if ($request->alert_type === 'IPO' && !filled(getSettingMode('finnhub_api_key'))) {
            return ResponseService::errorResponse(__('please_configure_your_finnhub_api_key_in_settings'));
        }

        // IPOs aren't tradeable yet - no quote to fetch, just record the pick.
        if ($request->alert_type === 'IPO') {
            Alerts::create([
                'alert_type'      => $request->alert_type,
                'name'            => $request->name,
                'symbol'          => $request->symbol,
                'exchange'        => $request->exchange,
                'ipo_price'       => $request->ipo_price,
                'current_price'   => null,
                'currency'        => null,
                'percent_change'  => null,
                'direction'       => null,
                'status'          => $request->status ?? 0,
                'last_updated_at' => now(),
            ]);

            return ResponseService::successResponse(__('created_success'));
        }

        $currentPrice  = null;
        $currency      = null;
        $percentChange = null;
        $direction     = null;
        $lastUpdatedAt = now();

        try {
            $quote = $this->twelveDataService->getQuote($request->symbol);
            // dd($quote);

            $currentPrice  = $quote['current_price'];
            $currency      = $quote['currency'];
            $percentChange = $quote['percent_change'];
            $direction     = $quote['direction'];
            $lastUpdatedAt = $quote['last_updated_at'];

            Alerts::create([
                'alert_type'      => $request->alert_type,
                'name'            => $request->name,
                'symbol'          => $request->symbol,
                'exchange'        => $request->exchange,
                'current_price'   => $currentPrice,
                'currency'        => $currency,
                'percent_change'  => $percentChange,
                'direction'       => $direction,
                'status'          => $request->status ?? 0,
                'last_updated_at' => $lastUpdatedAt,
            ]);
            return ResponseService::successResponse(__('created_success'));
        } catch (Throwable $e) {
            Log::error('AlertsController -> store ' . $e->getMessage() . '---> ' . $e->getFile() . ' At Line : ' . $e->getLine());
            // return ResponseService::errorResponse($e->getMessage());
            return ResponseService::errorResponse(__('incorrect_symbol_or_api_key'));
        }
    }


    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request)
    {
        $request->validate([
            'edit_id'    => 'required|integer|exists:alerts,id',
            'alert_type' => 'required|in:stock,commodity,forex,Crypto,IPO',
            'symbol'     => 'required|string|max:50',
            'name'       => 'required|string|max:255',
            'exchange'   => 'nullable|string|max:50',
            'ipo_price'  => 'nullable|string|max:50',
            'status'     => 'required|boolean',
        ]);

        $alert = Alerts::findOrFail($request->edit_id);

        if (in_array($request->alert_type, TwelveDataService::PENDING_TYPES, true)) {
            return ResponseService::errorResponse(__(':type_alerts_are_coming_soon', ['type' => $request->alert_type]));
        }

        if ($request->alert_type !== $alert->alert_type && $this->twelveDataService->hasAlertOfType($request->alert_type)) {
            return ResponseService::errorResponse(__('an_active_:type_alert_already_exists_delete_it_before_adding_a_new_one', ['type' => $request->alert_type]));
        }

        // apikey validation
        if ($request->alert_type !== 'IPO' && !filled(getSettingMode('twelvedata_api_key'))) {
            return ResponseService::errorResponse(__('please_configure_your_twelvedata_api_key_in_settings'));
        }
        if ($request->alert_type === 'IPO' && !filled(getSettingMode('finnhub_api_key'))) {
            return ResponseService::errorResponse(__('please_configure_your_finnhub_api_key_in_settings'));
        }

        // IPOs aren't tradeable yet - no quote to fetch, just record the pick.
        if ($request->alert_type === 'IPO') {
            $alert->update([
                'alert_type'      => $request->alert_type,
                'name'            => $request->name,
                'symbol'          => $request->symbol,
                'exchange'        => $request->exchange,
                'ipo_price'       => $request->ipo_price,
                'current_price'   => null,
                'currency'        => null,
                'percent_change'  => null,
                'direction'       => null,
                'status'          => $request->status ?? 0,
                'last_updated_at' => now(),
            ]);

            return ResponseService::successResponse(__('updated_success'));
        }

        $currentPrice  = null;
        $currency      = null;
        $percentChange = null;
        $direction     = null;
        $lastUpdatedAt = now();

        try {
            $quote = $this->twelveDataService->getQuote($request->symbol);

            $currentPrice  = $quote['current_price'];
            $currency      = $quote['currency'];
            $percentChange = $quote['percent_change'];
            $direction     = $quote['direction'];
            $lastUpdatedAt = $quote['last_updated_at'];

            $alert->update([
                'alert_type'      => $request->alert_type,
                'name'            => $request->name,
                'symbol'          => $request->symbol,
                'exchange'        => $request->exchange,
                'current_price'   => $currentPrice,
                'currency'        => $currency,
                'percent_change'  => $percentChange,
                'direction'       => $direction,
                'status'          => $request->status ?? 0,
                'last_updated_at' => $lastUpdatedAt,
            ]);

            return ResponseService::successResponse(__('updated_success'));
        } catch (Throwable $e) {
            Log::error('AlertsController -> update ' . $e->getMessage() . '---> ' . $e->getFile() . ' At Line : ' . $e->getLine());
            return ResponseService::errorResponse(__('incorrect_symbol_or_api_key'));
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Alerts $alert)
    {
        try {
            $alert->delete();
            return ResponseService::successResponse(__('deleted_success'));
        } catch (\Exception $e) {
            return ResponseService::errorResponse($e->getMessage());
        }
    }

}
