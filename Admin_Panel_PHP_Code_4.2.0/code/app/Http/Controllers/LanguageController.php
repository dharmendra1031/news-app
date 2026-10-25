<?php

namespace App\Http\Controllers;

use App\Models\Language;
use App\Models\Settings;
use App\Services\ResponseService;
use Exception;
use App\Services\FileService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Response;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class LanguageController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['language-list', 'language-create', 'language-edit', 'language-delete']);
        try {
            return view('language');
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, "LanguageController -> index");
        }
    }

    public function downloadPanelJson(Request $request)
    {
        try{

            $langFile = $request->lang . '.json';
            $file = base_path('resources/lang/') . $langFile;
            $filename = 'panel-' . $langFile;
            return Response::download($file, $filename, [
                'Content-Type' => 'application/json',
            ]);
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "LanguageController -> downloadPanelJson");
        }
    }

    public function downloadAppJson()
    {
        try{
            $langFile = 'en_app.json';
            $file = resource_path('lang/') . $langFile;
            return Response::download($file, $langFile, [
                'Content-Type' => 'application/json',
            ]);
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "LanguageController -> downloadAppJson");
        }
    }
    public function downloadWebJson()
    {
        try{
            $langFile = 'en_web.json';
            $file = resource_path('lang/') . $langFile;
            return Response::download($file, $langFile, [
                'Content-Type' => 'application/json',
            ]);
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "LanguageController -> downloadWebJson");
        }
    }

    public function set_language(Request $request)
    {
        try{Session::put('locale', $request->lang);
        $language = Language::where('code', $request->lang)->first();
        Session::put('language_name', $language->language);
        Session::put('language_code', $language->code);
        // Session::put('language', $language);
        // Session::put('isRTL', $language->isRTL);
        Session::save();
        app()->setLocale(Session::get('locale'));
        return redirect()->back();
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "LanguageController -> set_language");
        }
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('language-list');
        $default_lang = getSetting('default_language');
        $default_lang_value = $default_lang['default_language'];

        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'status');
        $order = $request->input('order', 'DESC');

        $sql = Language::orderBy($sort, $order);
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            if (!empty($search)) {
                $sql->where('id', 'LIKE', "%{$search}%")
                    ->orWhere('language', 'LIKE', "%{$search}%")
                    ->orWhere('code', 'LIKE', "%{$search}%")
                    ->orWhere('language', 'LIKE', "%{$search}%");
            }
        }
        $total = $sql->count('id');
        $sql = $sql->skip($offset)->take($limit);
        $rows = $sql->get()->map(function ($row) use ($default_lang_value) {
            $edit = '';
            if (auth()->user()->can('language-edit')) {
                $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }
            $delete = '';
            if (auth()->user()->can('language-delete')) {
                if ($default_lang_value != $row->id) {
                    $delete = '<a data-url="' . url('language', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
                }
            }
            $operate = '';
            if ($edit == '' && $delete == '') {
                $operate = '-';
            } else {
                $operate =
                '<div class="dropdown">
                            <a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
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

            if ($default_lang_value == $row->id) {
                $default = '<span class="badge badge-secondary"><em class="fa fa-check"></em> Default</span>';
            } elseif ($row->status == 1) {
                $default = '<a class="btn btn-icon btn-sm btn-info text-white store_default_language" data-id="' . $row->id . '"><em class="fa fa-ellipsis-h"></em> Set as Default</a>';
            } else {
                $default = '<a class="btn btn-icon btn-sm btn-info text-white store_default_language disabled" data-id="' . $row->id . '"><em class="fa fa-ellipsis-h"></em> Set as Default</a>';
            }

            return [
                'id' => $row->id,
                'language' => $row->language,
                'display_name' => $row->display_name ?? '',
                'code' => $row->code,
                'isRTL' => $row->isRTL == 1 ? '<span class="badge badge-success">Yes</span>' : '<span class="badge badge-danger">No</span>',
                'image' => !empty($row->image) ? '<a href=' . $row->image . '  data-toggle="lightbox" data-title="Image"><img src=' . $row->image . ' height=50, width=50 >' : '-',
                'default1' => $default,
                'is_default' => $default_lang_value == $row->id ? 1 : 0,
                'isRtl_value' => $row->isRTL,
                'status' => $row->status,
                'status1' => $row->status == 1 ? '<span class="badge badge-success">' . __('active') . '</span>' : '<span class="badge badge-danger">' . __('deactive') . '</span>',
                'app_json' => !empty($row->getRawOriginal('app_file')) ? '<a class="btn btn-sm btn-info" href="' . route('languageedit', [$row->id, 'app']) . '"><i class="fa fa-download"></i></a>' : '-',
                'web_json' => !empty($row->getRawOriginal('web_file')) ? '<a class="btn btn-sm btn-info" href="' . route('languageedit', [$row->id, 'web']) . '"><i class="fa fa-download"></i></a>' : '-',
                'panel_json' => !empty($row->getRawOriginal('panel_file')) ? '<a class="btn btn-sm btn-info" href="' . route('languageedit', [$row->id, 'panel']) . '"><i class="fa fa-download"></i></a>' : '-',
                // 'web_json' => !empty($row->getRawOriginal('web_file')) ? '<a class="btn btn-sm btn-info" href="' . url(Storage::url($row->getRawOriginal('web_file'))) . '"><i class="fa fa-download"></i></a>' : '-',
                // 'panel_json' => '<a class="btn btn-sm btn-info" href="' . url('download-panel-json') . '/' . $row->code . '"><i class="fa fa-download"></i></a>',
                'operate' => $operate,
            ];
        });

        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }

    public function store(Request $request)
    {
        ResponseService::noPermissionThenRedirect('language-create');

        try{
            $validator = Validator::make($request->all(), [
                'language' => 'required|string|max:255',
                'display_name' => 'required|string|max:255',
                'code' => 'required|unique:tbl_languages|max:2',
                'app_json' => 'nullable|file|mimes:json',
                'web_json' => 'nullable|file|mimes:json',
                'admin_json' => 'nullable|file|mimes:json',
                'flag' => 'required|image|mimes:png,jpg,jpeg,svg,webp'
            ]);
            if ($validator->fails()) {
                return ResponseService::errorResponse($validator->errors()->first(), null, 422, null);
            }
            $image = '';
            if ($request->hasFile('flag')) {
                $image = compressAndUpload($request->file('flag'), 'flags');
            }

            $language_code = $request->code;
            $appFile = '';
            $webFile = '';
            $panelFile = '';

            if ($request->hasFile('app_json')) {
                $appFile = FileService::uploadLanguageFile($request->file('app_json'), $language_code.'_app');
            }
            if ($request->hasFile('web_json')) {
                $webFile = FileService::uploadLanguageFile($request->file('web_json'), $language_code.'_web');
            }
            if ($request->hasFile('admin_json')) {
                $panelFile = FileService::uploadLanguageFile($request->file('admin_json'), $language_code);
            }

            Language::create([
                'language' => $request->language,
                'code' => $language_code,
                'status' => 1,
                'isRTL' => $request->is_rtl_switch === 'on' ? 1 : 0,
                'image' => $image,
                'display_name' => $request->display_name ?? '',
                'app_file' => $appFile,
                'web_file' => $webFile,
                'panel_file' => $panelFile,
            ]);

            return ResponseService::successResponse(__('created_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "LanguageController -> store");
        }
    }

    public function update(Request $request)
    {
        ResponseService::noPermissionThenRedirect('language-edit');
        try {
            $request->validate(
                [
                    'language' => 'required',
                    'code' => 'required|unique:tbl_languages,code,' . $request->edit_id . ',id',
                ],
                [
                    'code.unique' => __('language_code_unique'), //Code already exists.
                ],
            );

            $language = Language::find($request->edit_id);
            $language->language = $request->language;
            $language->display_name = $request->display_name;
            $language->code = $request->code;
            $language->isRTL = $request->is_rtl_switch === 'on' ? 1 : 0;
            if ($request->hasFile('flag')) {
                $language->image = compressAndReplace($request->file('flag'), 'flags', $language->getRawOriginal('image'));
            }
            $language->status = $request->status;
            // $language->save();

            if ($request->hasFile('edit_app_json')) {
                $appFile = FileService::uploadLanguageFile($request->file('edit_app_json'), $request->code.'_app');
                $language->app_file = $appFile;
            }

            if ($request->hasFile('edit_web_json')) {
                $webFile = FileService::uploadLanguageFile($request->file('edit_web_json'), $request->code.'_web');
                $language->web_file = $webFile;
            }

            if ($request->hasFile('edit_json_admin')) {
                $panelFile = FileService::uploadLanguageFile($request->file('edit_json_admin'), $request->code);
                $language->panel_file = $panelFile;
            }
            $language->save();
            return ResponseService::successResponse(__('updated_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "LanguageController -> update");
        }
    }

    public function destroy(string $id)
    {
        ResponseService::noPermissionThenRedirect('language-delete');
        try{
            $language = Language::find($id);
            if ($language->code != 'en') {
                FileService::deleteLanguageFile($language->getRawOriginal('app_file'));
                FileService::deleteLanguageFile($language->getRawOriginal('web_file'));
                FileService::deleteLanguageFile($language->getRawOriginal('panel_file'));
            }
            $language->delete();

            return ResponseService::successResponse(__('deleted_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "LanguageController -> destroy");
        }
    }

    public function store_default_language(Request $request)
    {
        try {
            $setting = getSetting('default_language');
            if (empty($setting)) {
                $setting = new Settings();
                $setting->type = 'default_language';
                $setting->message = $request->id;
                session()->forget('locale');
                session()->forget('language_name');
                $setting->save();
            } else {
                $setting = Settings::where('type', 'default_language')->first();
                $setting->message = $request->id;
                session()->forget('locale');
                session()->forget('language_name');
                $setting->save();
            }
            return ResponseService::successResponse(__('updated_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "LanguageController -> store_default_language");
        }
    }

    public function editlanguage(Request $request, $id, $type)
    {
        $language = Language::findOrFail($id);
        $languageCode = $language->code ?? 'en';
        //        $name = $type;

        if ($type == 'panel') {
            $fileName = $language->panel_file ?: "{$languageCode}.json";
            $defaultFile = base_path('resources/lang/en.json');
        } elseif ($type == 'web') {
            $fileName = $language->web_file ?: "{$languageCode}_web.json";
            $defaultFile = base_path('resources/lang/en_web.json');
        } elseif ($type == 'app') {
            $fileName = $language->app_file ?: "{$languageCode}_app.json";
            $defaultFile = base_path('resources/lang/en_app.json');
        } else {
            $fileName = 'en.json';
            $defaultFile = base_path('resources/lang/en.json');
        }

        $jsonFile = base_path("resources/lang/{$fileName}");

        if (!File::exists($jsonFile)) {
            if (File::exists($defaultFile)) {
                $defaultContent = File::get($defaultFile);
            } else {
                $defaultContent = json_encode([]);
            }

            File::put($jsonFile, $defaultContent);

            if ($type == 'panel') {
                $language->panel_file = $fileName;
            } elseif ($type == 'web') {
                $language->web_file = $fileName;
            } elseif ($type == 'app') {
                $language->app_file = $fileName;
            }
            $language->save();
        }

        $jsonContent = File::get($jsonFile);

        $enContent = File::exists($defaultFile) ? json_decode(File::get($defaultFile), true) : [];
        $targetContent = File::exists($jsonFile) ? json_decode(File::get($jsonFile), true) : [];

        // download file
        return response()->download($jsonFile);
        foreach ($enContent as $key => $value) {
            if (!array_key_exists($key, $targetContent)) {
                $targetContent[$key] = $value;
            }
        }
        File::put($jsonFile, json_encode($targetContent, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
        $enLabels = json_decode($jsonContent, true);

        // return view('settings.languageedit', compact('enLabels', 'language', 'type'));
    }
}
