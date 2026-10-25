<?php

namespace App\Http\Controllers;

use App\Models\Admin;
use App\Models\News;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class AuthController extends Controller
{
    /**
     * Instantiate a new LoginRegisterController instance.
     */
    public function __construct()
    {
        $this->middleware('guest')->except(['logout', 'home']);
    }
    /**
     * Display a registration form.
     *
     * @return \Illuminate\Http\Response
     */
    public function register()
    {
        return view('auth.register');
    }

    /**
     * Store a new user.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:250',
            'email' => 'required|email|max:250|unique:users',
            'password' => 'required|min:8|confirmed',
        ]);
        User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);
        $credentials = $request->only('email', 'password');
        Auth::attempt($credentials);
        $request->session()->regenerate();
        return redirect()->route('dashboard')->withSuccess('You have successfully registered & logged in!');
    }
    /**
     * Display a login form.
     *
     * @return \Illuminate\Http\Response
     */
    public function login()
    {
        $setting = getSetting();
        return view('auth.login', compact('setting'));
    }
    /**
     * Authenticate the user.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function authenticate(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        $credentials = [
            'password' => $request->password,
        ];

        // Determine if the input is an email or username
        if (filter_var($request->username, FILTER_VALIDATE_EMAIL)) {
            $credentials['email'] = $request->username; // Use email for authentication
        } else {
            $credentials['username'] = $request->username; // Use username for authentication
        }

        if (Auth::guard('admin')->attempt($credentials)) {
            $user = Auth::guard('admin')->user();

            if ($user->status != 1) {
                Auth::guard('admin')->logout();
                return redirect()->route('login')->with('error', 'Your account is inactive. Please contact the administrator.');
            }

            $request->session()->regenerate();
            $language = get_default_language();
            if ($language) {
                session(['language_name' => $language->language]);
            }
            if (is_auto_news_expire_news_enabled() == 1) {
                // AutoDelete Expire News
                News::where('show_till', '<', date('Y-m-d'))->where('show_till', '!=', '0000-00-00')->delete();
            } else {
                // Auto update News status based on show_till
                News::where('is_clone', 0)->where('status', 1)->where('show_till', '<>', '0000-00-00')->where('show_till', '<', date('Y-m-d'))->update(['status' => 0]);
            }
            return redirect()->route('home')->withSuccess('You have successfully logged in!');
        }

        return redirect()->route('login')->with('error', 'Invalid Username or Password');
    }

    /**
     * Log out the user from application.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function logout(Request $request)
    {
        Auth::guard('admin')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('login')->withSuccess('You have logged out successfully!');
    }

    public function check_email(Request $request)
    {
        $email = $request->email;
        $admin = Admin::where('email', $email)->first();
        if (!$admin) {
            return response()->json(false);
        }
        $forgot_unique_code = generateRandomString();
        $admin->forgot_unique_code = $forgot_unique_code;
        $admin->forgot_at = now();
        $admin->save();
        $data = [
            'forgot_unique_code' => $forgot_unique_code,
            'forgot_at' => now(),
            'subject' => 'Forgot Password',
            'full_url' => url('reset_password?forgot_code=' . $forgot_unique_code), // Include $full_url in the data array
        ];
        Mail::send(['text' => 'mail'], $data, function ($message) use ($email, $admin, $data) {
            $message
                ->to($email)
                ->subject($data['subject'])
                ->html("Dear {$admin->username},<br>Your password reset link is {$data['full_url']}. Click it to proceed further.<br>Subject: {$data['subject']}");
            $message->from(is_email_setting()->SMTPUser, 'News Admin Panel');
        });
        return response()->json(true);
    }

    public function reset_password()
    {
        $settings = getSetting();
        return view('auth.reset', ['setting' => $settings]);
    }

    public function update_password(Request $request)
    {
        $password = $request->password;
        $confirm_password = $request->confirm_password;
        $forgot_code = $request->forgot_unique_code;
        $is_exist_forgot_unique_code = Admin::where('forgot_unique_code', $forgot_code)->first();
        if ($is_exist_forgot_unique_code) {
            $forgot_unique_code = $is_exist_forgot_unique_code->forgot_unique_code;
            $forgot_at = $is_exist_forgot_unique_code->forgot_at;
            $id = $is_exist_forgot_unique_code->id;
            $username = $is_exist_forgot_unique_code->username;
            $email = $is_exist_forgot_unique_code->email;
            if (!empty($forgot_at) && $forgot_code === $forgot_unique_code && strtotime($forgot_at) > strtotime('-24 hours')) {
                if (!empty($password) && !empty($confirm_password) && $password === $confirm_password) {
                    $pass = bcrypt($confirm_password);
                    $admin = Admin::find($id);
                    $admin->password = $pass;
                    $admin->forgot_unique_code = '';
                    $admin->forgot_at = '';
                    $admin->save();
                    $data = [
                        'subject' => 'Forgot Password',
                    ];
                    Mail::send([], $data, function ($message) use ($email, $username, $data, $password) {
                        $message
                            ->to($email)
                            ->subject($data['subject'])
                            ->html("Dear $username, <br/> Your password reset successfully. New password is <strong>$password</strong>.<br/>Thank You!!");
                        $message->from(is_email_setting()->SMTPUser, 'News Admin Panel');
                    });
                    $data = [
                        'error' => false,
                        'message' => 'Password Change Successfully..',
                    ];
                    return response()->json($data);
                } else {
                    $data = [
                        'error' => true,
                        'message' => 'New and Confirm Password not Match..',
                    ];
                    return response()->json($data);
                }
            } else {
                $data = [
                    'error' => true,
                    'message' => 'Reset Password link is expired, please try again.',
                ];
                return response()->json($data);
            }
        } else {
            $data = [
                'error' => true,
                'message' => 'Link is invalid',
            ];
            return response()->json($data);
        }
    }
}
