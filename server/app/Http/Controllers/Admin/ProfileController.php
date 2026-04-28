<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    public function index()
    {
        $user = Auth::user();

        if (!$user instanceof User) {
            abort(403, 'User tidak ditemukan.');
        }

        return view('profile.index', compact('user'));
    }

    public function update(Request $request)
    {
        $user = Auth::user();

        if (!$user instanceof User) {
            abort(403, 'User tidak ditemukan.');
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],

            'username' => [
                'nullable',
                'string',
                'max:255',
                Rule::unique('users', 'username')->ignore($user->id),
            ],

            'email' => [
                'required',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($user->id),
            ],

            'phone' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string', 'max:1000'],
            'profile_photo' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],

            'current_password' => ['nullable', 'string'],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
        ], [
            'name.required' => 'Nama wajib diisi.',
            'email.required' => 'Email wajib diisi.',
            'email.email' => 'Format email tidak valid.',
            'email.unique' => 'Email sudah digunakan user lain.',
            'username.unique' => 'Username sudah digunakan user lain.',
            'profile_photo.image' => 'File harus berupa gambar.',
            'profile_photo.mimes' => 'Foto harus berformat jpg, jpeg, png, atau webp.',
            'profile_photo.max' => 'Ukuran foto maksimal 2MB.',
            'password.min' => 'Password baru minimal 8 karakter.',
            'password.confirmed' => 'Konfirmasi password baru tidak sama.',
        ]);

        if ($request->filled('password')) {
            if (!$request->filled('current_password')) {
                return back()
                    ->withErrors([
                        'current_password' => 'Password lama wajib diisi jika ingin mengganti password.',
                    ])
                    ->withInput();
            }

            if (!Hash::check($request->current_password, $user->password)) {
                return back()
                    ->withErrors([
                        'current_password' => 'Password lama tidak sesuai.',
                    ])
                    ->withInput();
            }

            $user->password = $validated['password'];
        }

        $user->name = $validated['name'];
        $user->username = $validated['username'] ?? null;
        $user->email = $validated['email'];
        $user->phone = $validated['phone'] ?? null;
        $user->address = $validated['address'] ?? null;

        if ($request->hasFile('profile_photo')) {
            if ($user->profile_photo && Storage::disk('public')->exists($user->profile_photo)) {
                Storage::disk('public')->delete($user->profile_photo);
            }

            $user->profile_photo = $request->file('profile_photo')->store('profile-photos', 'public');
        }

        $user->save();

        return redirect()
            ->route('admin.profile.index')
            ->with('success', 'Profile berhasil diperbarui.');
    }

    public function destroyPhoto()
    {
        $user = Auth::user();

        if (!$user instanceof User) {
            abort(403, 'User tidak ditemukan.');
        }

        if ($user->profile_photo && Storage::disk('public')->exists($user->profile_photo)) {
            Storage::disk('public')->delete($user->profile_photo);
        }

        $user->profile_photo = null;
        $user->save();

        return redirect()
            ->route('admin.profile.index')
            ->with('success', 'Foto profile berhasil dihapus.');
    }
}