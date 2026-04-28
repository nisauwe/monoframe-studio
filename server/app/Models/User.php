<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Models\RolePermission;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
  /** @use HasFactory<\Database\Factories\UserFactory> */
  use HasApiTokens, HasFactory, Notifiable;

  /**
   * The attributes that are mass assignable.
   *
   * @var list<string>
   */
  protected $fillable = [
    'username',
    'name',
    'email',
    'phone',
    'address',
    'profile_photo',
    'role',
    'is_active',
    'password',
    'booking_buffer_minutes',
  ];

  /**
   * The attributes that should be hidden for serialization.
   *
   * @var list<string>
   */
  protected $hidden = [
    'password',
    'remember_token',
  ];

  /**
   * Get the attributes that should be cast.
   *
   * @return array<string, string>
   */
  protected function casts(): array
  {
    return [
      'email_verified_at' => 'datetime',
      'password' => 'hashed',
      'is_active' => 'boolean',
    ];
  }

  public function hasPermission(string $permissionKey): bool
  {
    if (($this->role ?? null) === 'Admin') {
      return true;
    }

    if (property_exists($this, 'is_active') && $this->is_active === false) {
      return false;
    }

    return RolePermission::where('role_name', $this->role)
      ->where('permission_key', $permissionKey)
      ->exists();
  }

  public function photographerBookings()
  {
    return $this->hasMany(\App\Models\ScheduleBooking::class, 'photographer_user_id');
  }

  public function uploadedPhotoLinks()
  {
    return $this->hasMany(\App\Models\PhotoLink::class, 'photographer_user_id');
  }

  public function clientEditRequests()
  {
    return $this->hasMany(\App\Models\EditRequest::class, 'client_user_id');
  }

  public function handledEditRequests()
  {
    return $this->hasMany(\App\Models\EditRequest::class, 'editor_user_id');
  }
}