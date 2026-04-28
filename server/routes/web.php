<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Admin\CategoryController;
use App\Http\Controllers\Admin\PackageController;
use App\Http\Controllers\Admin\DiscountController;
use App\Http\Controllers\Admin\ScheduleController;
use App\Http\Controllers\Admin\CalendarController;
use App\Http\Controllers\Admin\RoleAccessController;
use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminForgotPasswordController;
use App\Http\Controllers\Admin\AdminResetPasswordController;
use App\Http\Controllers\Admin\PaymentGatewayController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\Admin\PaymentController as AdminPaymentController;
use App\Http\Controllers\Admin\PrintPriceController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\CallCenterContactController;
use App\Http\Controllers\Admin\ReviewController;
use App\Http\Controllers\Admin\ProfileController;

Route::get('/', function () {
  return redirect()->route('admin.login');
});

// route global yang dicari middleware auth Laravel
Route::get('/login', function () {
  return redirect()->route('admin.login');
})->name('login');

Route::get('/reset-password/{token}', [AdminResetPasswordController::class, 'showResetForm'])
  ->middleware('guest')
  ->name('password.reset');

Route::post('/reset-password', [AdminResetPasswordController::class, 'reset'])
  ->middleware('guest')
  ->name('password.update');

Route::prefix('admin')->name('admin.')->middleware(['auth', 'admin.only'])->group(function () {
  Route::get('/payments', [AdminPaymentController::class, 'index'])->name('payments.index');
  Route::post('/payments/incomes', [AdminPaymentController::class, 'storeIncome'])->name('payments.incomes.store');
  Route::delete('/payments/incomes/{income}', [AdminPaymentController::class, 'destroyIncome'])->name('payments.incomes.destroy');

  Route::post('/payments/expenses', [AdminPaymentController::class, 'storeExpense'])->name('payments.expenses.store');
  Route::delete('/payments/expenses/{expense}', [AdminPaymentController::class, 'destroyExpense'])->name('payments.expenses.destroy');
  Route::get('/payments/{payment}', [AdminPaymentController::class, 'show'])->name('payments.show');

  Route::get('/reviews', [ReviewController::class, 'index'])->name('reviews.index');
  Route::delete('/reviews/{review}', [ReviewController::class, 'destroy'])->name('reviews.destroy');
});

Route::prefix('admin')->name('admin.')->group(function () {
  Route::middleware('guest')->group(function () {
    Route::get('/login', [AdminAuthController::class, 'showLoginForm'])->name('login');
    Route::post('/login', [AdminAuthController::class, 'login'])->name('login.submit');

    Route::get('/forgot-password', [AdminForgotPasswordController::class, 'showLinkRequestForm'])->name('password.request');
    Route::post('/forgot-password', [AdminForgotPasswordController::class, 'sendResetLinkEmail'])->name('password.email');

    Route::get('/reset-password/{token}', [AdminResetPasswordController::class, 'showResetForm'])->name('password.reset');
    Route::post('/reset-password', [AdminResetPasswordController::class, 'reset'])->name('password.update');
  });

  Route::middleware(['auth', 'admin.only'])->group(function () {
    Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    Route::get('/profile', [ProfileController::class, 'index'])->name('profile.index');
    Route::put('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile/photo', [ProfileController::class, 'destroyPhoto'])->name('profile.photo.destroy');
  });

  Route::get('/users', [UserController::class, 'index'])->middleware('permission:users.manage')->name('users.index');
  Route::get('/users/create', [UserController::class, 'create'])->name('users.create');
  Route::post('/users', [UserController::class, 'store'])->name('users.store');

  Route::get('/users/export/excel', [UserController::class, 'exportExcel'])->middleware('permission:users.manage')->name('users.export.excel');
  Route::get('/users/export/pdf', [UserController::class, 'exportPdf'])->middleware('permission:users.manage')->name('users.export.pdf');

  Route::get('/users/{user}/edit', [UserController::class, 'edit'])->name('users.edit');
  Route::put('/users/{user}', [UserController::class, 'update'])->name('users.update');
  Route::delete('/users/{user}', [UserController::class, 'destroy'])->name('users.destroy');

  Route::delete('/users/reset', [UserController::class, 'resetAll'])->name('users.reset');

  Route::get('/categories/create', [CategoryController::class, 'create'])->name('categories.create');
  Route::post('/categories', [CategoryController::class, 'store'])->name('categories.store');
  Route::patch('/categories/{category}/toggle-status', [CategoryController::class, 'toggleStatus'])->name('categories.toggle-status');
  Route::delete('/categories/{category}', [CategoryController::class, 'destroy'])->name('categories.destroy');

  Route::get('/packages', [PackageController::class, 'index'])->middleware('permission:packages.view')->name('packages.index');
  Route::get('/packages/create', [PackageController::class, 'create'])->middleware('permission:packages.manage')->name('packages.create');
  Route::post('/packages', [PackageController::class, 'store'])->name('packages.store');

  Route::get('/packages/{package}/edit', [PackageController::class, 'edit'])->name('packages.edit');
  Route::put('/packages/{package}', [PackageController::class, 'update'])->name('packages.update');
  Route::delete('/packages/{package}', [PackageController::class, 'destroy'])->name('packages.destroy');
  Route::patch('/packages/{package}/toggle-status', [PackageController::class, 'toggleStatus'])->name('packages.toggle-status');

  Route::get('/print-prices/create', [PrintPriceController::class, 'create'])->name('print-prices.create');
  Route::post('/print-prices', [PrintPriceController::class, 'store'])->name('print-prices.store');
  Route::get('/print-prices/{printPrice}/edit', [PrintPriceController::class, 'edit'])->name('print-prices.edit');
  Route::put('/print-prices/{printPrice}', [PrintPriceController::class, 'update'])->name('print-prices.update');
  Route::delete('/print-prices/{printPrice}', [PrintPriceController::class, 'destroy'])->name('print-prices.destroy');
  Route::patch('/print-prices/{printPrice}/toggle-status', [PrintPriceController::class, 'toggleStatus'])->name('print-prices.toggle-status');

  Route::get('/discounts/create', [DiscountController::class, 'create'])->name('discounts.create');
  Route::post('/discounts', [DiscountController::class, 'store'])->name('discounts.store');
  Route::get('/discounts/{discount}/edit', [DiscountController::class, 'edit'])->name('discounts.edit');
  Route::put('/discounts/{discount}', [DiscountController::class, 'update'])->name('discounts.update');
  Route::patch('/discounts/{discount}/toggle-status', [DiscountController::class, 'toggleStatus'])->name('discounts.toggle-status');

  Route::get('/schedules', [ScheduleController::class, 'index'])->middleware('permission:schedules.daily.view')->name('schedules.index');
  Route::put('/schedules/rules', [ScheduleController::class, 'updateRules'])->name('schedules.rules.update');
  Route::get('/schedules/available-slots', [ScheduleController::class, 'availableSlots'])->name('schedules.available-slots');
  Route::get('/schedules/available-photographers', [ScheduleController::class, 'availablePhotographers'])->name('schedules.available-photographers');
  Route::post('/schedules/manual-request', [ScheduleController::class, 'storeManualRequest'])->name('schedules.manual-request.store');

  Route::put('/schedules/addon-settings', [ScheduleController::class, 'updateAddonSettings'])->name('schedules.addon-settings.update');

  Route::get('/calendar', [CalendarController::class, 'index'])->middleware('permission:calendar.view')->name('calendar.index');
  Route::post('/calendar', [CalendarController::class, 'store'])->name('calendar.store');

  Route::get('/roles-akses', [RoleAccessController::class, 'index'])->middleware('permission:users.manage')->name('roles-akses.index');
  Route::post('/roles-akses/roles', [RoleAccessController::class, 'storeRole'])->middleware('permission:users.manage')->name('roles-akses.roles.store');
  Route::put('/roles-akses/permissions', [RoleAccessController::class, 'updatePermissions'])->middleware('permission:users.manage')->name('roles-akses.permissions.update');
  Route::post('/roles-akses/reset-defaults', [RoleAccessController::class, 'resetDefaults'])->middleware('permission:users.manage')->name('roles-akses.reset-defaults');
  Route::patch('/roles-akses/users/{user}/toggle', [RoleAccessController::class, 'toggleUserAccess'])->middleware('permission:users.manage')->name('roles-akses.users.toggle');

  Route::get('/payment-gateway', [PaymentGatewayController::class, 'index'])->name('payment-gateway.index');
  Route::post('/payment-gateway', [PaymentGatewayController::class, 'update'])->name('payment-gateway.update');
  Route::post('/payment-gateway/test', [PaymentGatewayController::class, 'testConnection'])->name('payment-gateway.test');
  Route::post('/payment-gateway/reset', [PaymentGatewayController::class, 'resetConfig'])->name('payment-gateway.reset');

  Route::middleware('auth')->group(function () {
    Route::post('/payments/{scheduleBooking}/snap', [PaymentController::class, 'createSnap'])
      ->name('payments.snap');
  });
  Route::post('/payment/midtrans/notification', [PaymentController::class, 'notification'])->name('payments.midtrans.notification');
  Route::get('/payment/finish', [PaymentController::class, 'finish'])->name('payments.finish');
  Route::get('/payment/unfinish', [PaymentController::class, 'unfinish'])->name('payments.unfinish');
  Route::get('/payment/error', [PaymentController::class, 'error'])->name('payments.error');

  Route::get('/call-center', [CallCenterContactController::class, 'index'])->name('call-center.index');
  Route::post('/call-center', [CallCenterContactController::class, 'store'])->name('call-center.store');
  Route::put('/call-center/{callCenter}', [CallCenterContactController::class, 'update'])->name('call-center.update');
  Route::delete('/call-center/{callCenter}', [CallCenterContactController::class, 'destroy'])->name('call-center.destroy');
  Route::patch('/call-center/{callCenter}/toggle-status', [CallCenterContactController::class, 'toggleStatus'])->name('call-center.toggle-status');

  
});
