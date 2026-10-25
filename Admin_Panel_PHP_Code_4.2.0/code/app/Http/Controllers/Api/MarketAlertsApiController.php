<?php

namespace App\Http\Controllers\Api;

use App\Models\Alerts;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use App\Services\ResponseService;
use Exception;

class MarketAlertsApiController extends BaseApiController
{
    /**
     * Fetch active market alerts (stock, commodity, forex, Crypto, IPO) - all
     * types in one response, optionally narrowed by type/search.
     */
    public function getMarketAlerts(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'alert_type'   => 'nullable|string|in:stock,commodity,forex,Crypto,IPO',
                'search'       => 'nullable|string|max:255',
                'limit'        => 'nullable|integer|min:1|max:100',
                'order_column' => 'nullable|string',
                'order_by'     => 'nullable|string|in:asc,desc,ASC,DESC',
                'offset'       => 'nullable|integer|min:0',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $limit  = $request->has('limit') ? (int) $request->limit : 10;
            $offset = $request->has('offset') ? (int) $request->offset : 0;

            $query = Alerts::where('status', 1)
                ->when($request->filled('alert_type'), function ($q) use ($request) {
                    $q->where('alert_type', $request->alert_type);
                })
                ->when($request->filled('search'), function ($q) use ($request) {
                    $q->where(function ($q2) use ($request) {
                        $q2->where('name', 'like', '%' . $request->search . '%')
                            ->orWhere('symbol', 'like', '%' . $request->search . '%')
                            ->orWhere('exchange', 'like', '%' . $request->search . '%');
                    });
                });

            $total = $query->count();

            if ($total == 0) {
                return ResponseService::successResponse(
                    __('No data found'),
                    [
                        'total' => 0,
                        'data'  => [],
                    ]
                );
            }

            $orderBy = $request->order_column;
            $sortBy  = $request->order_by ?? 'DESC';

            $data = $query->safeOrder($orderBy, $sortBy)
                ->skip($offset)
                ->take($limit)
                ->get();

            return ResponseService::successResponse(
                __('market_alerts_fetched_successfully'),
                [
                    'total' => $total,
                    'data'  => $data,
                ]
            );
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e);
            return ResponseService::errorResponse(
                __('Something Went Wrong'),
                null,
                config('constants.RESPONSE_CODE.EXCEPTION_ERROR'),
                $e
            );
        }
    }
}
