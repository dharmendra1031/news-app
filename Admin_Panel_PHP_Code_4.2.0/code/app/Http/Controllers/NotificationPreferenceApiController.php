<?php

namespace App\Http\Controllers;

use App\Models\NotificationPreference;
use App\Models\NotificationType;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class NotificationPreferenceApiController extends Controller
{
    /**
     * Get the authenticated user's notification preferences.
     * Types with no stored row default to enabled.
     */
    public function getPreference(Request $request)
    {
        try {
            return ResponseService::successResponse(__('Data fetched successfully'), $this->buildPreferenceList(Auth::id()));
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, 'NotificationPreferenceApiController -> getPreference');
        }
    }

    /**
     * Update the authenticated user's notification preferences.
     * Accepts a list of {notification_type_id, status}.
     */
    public function updatePreference(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'preferences'                            => 'required|array|min:1',
                'preferences.*.notification_type_id'     => 'required|integer|exists:notification_types,id',
                'preferences.*.status'                   => 'required|boolean',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            foreach ($request->input('preferences') as $preference) {
                if ($preference['status']) {
                    // Enabled matches the default for a missing row, so drop any stored
                    // override instead of inserting one — no row means "enabled".
                    NotificationPreference::where('user_id', Auth::id())
                        ->where('notification_type_id', $preference['notification_type_id'])
                        ->delete();
                } else {
                    NotificationPreference::updateOrCreate(
                        [
                            'user_id'               => Auth::id(),
                            'notification_type_id'  => $preference['notification_type_id'],
                        ],
                        ['status' => false]
                    );
                }
            }

            return ResponseService::successResponse(__('Preferences updated successfully'), $this->buildPreferenceList(Auth::id()));
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, 'NotificationPreferenceApiController -> updatePreference');
        }
    }

    private function buildPreferenceList($userId)
    {
        $statuses = NotificationPreference::where('user_id', $userId)->pluck('status', 'notification_type_id');

        return NotificationType::all()->map(function ($type) use ($statuses) {
            return [
                'id'      => $type->id,
                'key'     => $type->key,
                'label'   => $type->label,
                'enabled' => $statuses->has($type->id) ? (bool) $statuses->get($type->id) : true,
            ];
        })->values();
    }
}
