<?php

namespace App\Http\Controllers;
use App\Models\Admin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Password;

class PasswordResetController extends Controller
{
    public function showResetForm($token)
    {
        return view('auth.passwords.reset')->with(['token' => $token, 'email' => request('email')]);
    }
    public function sendResetLinkEmail(Request $request)
    {
        $email = $request->email;
        $email = 'wrteam.dimple@gmail.com';
        $admin = Admin::where('email', $email)->first();

        if ($admin) {
            // $forgotUniqueCode = \Illuminate\Support\Str::random(25);
            // $fullUrl = url('reset_password', ['forgot_code' => $forgotUniqueCode]);
            // $to = $email;
            // $subject = 'Forgot Password';
            // $message = "Dear $admin->username, <br/> Your password reset link is $fullUrl. Click it to proceed further.<br/>Thank You!!";
            // Mail::to($to)->send(new \App\Mail\ForgotPassword($subject, $message));
            $data = ['name' => 'Virat Gandhi'];
            dd(
                Mail::send(['text' => 'mail'], $data, function ($message) {
                    $message->to('wrteam.dimple@gmail.com', 'Tutorials Point')->subject('Laravel Basic Testing Mail');
                    $message->from('wrteam.dimple@gmail.com', 'Virat Gandhi');
                }),
            );
            echo 'Basic Email Sent. Check your inbox.';
            return response()->json(true);
        } else {
            return response()->json(false);
        }
    }
    public function reset(Request $request)
    {
        $request->validate([
            'token' => 'required',
            'email' => 'required|email',
            'password' => 'required|confirmed|min:8',
        ]);
        $status = Password::reset($request->only('email', 'password', 'password_confirmation', 'token'), function ($user, $password) {
            $user
                ->forceFill([
                    'password' => bcrypt($password),
                    'remember_token' => \Str::random(60),
                ])
                ->save();
            $user->setRememberToken(\Str::random(60));
        });
        return $status == Password::PASSWORD_RESET
            ? redirect()->route('login')->with('status', __($status))
            : back()
                ->withInput($request->only('email'))
                ->withErrors(['email' => __($status)]);
    }
}
