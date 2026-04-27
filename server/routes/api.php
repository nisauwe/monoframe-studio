<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\MidtransNotificationController;
use App\Http\Controllers\Api\MidtransPaymentSyncController;

use App\Http\Controllers\Api\Client\PackageController;
use App\Http\Controllers\Api\Client\ScheduleController;
use App\Http\Controllers\Api\Client\BookingController;
use App\Http\Controllers\Api\Client\TrackingController;
use App\Http\Controllers\Api\Client\PhotoLinkController as ClientPhotoLinkController;
use App\Http\Controllers\Api\Client\EditRequestController as ClientEditRequestController;
use App\Http\Controllers\Api\Client\BookingPaymentController;
use App\Http\Controllers\Api\Client\BookingAddonSettingController;
use App\Http\Controllers\Api\Client\CallCenterContactController as ClientCallCenterContactController;
use App\Http\Controllers\Api\Client\PrintOrderController as ClientPrintOrderController;
use App\Http\Controllers\Api\Client\PrintPaymentController as ClientPrintPaymentController;
use App\Http\Controllers\Api\Client\ReviewController as ClientReviewController;

use App\Http\Controllers\Api\Photographer\AssignedBookingController as PhotographerAssignedBookingController;
use App\Http\Controllers\Api\Photographer\PhotoLinkController as PhotographerPhotoLinkController;

use App\Http\Controllers\Api\Editor\EditRequestController as EditorEditRequestController;

use App\Http\Controllers\Api\FrontOffice\ManualBookingController as FrontOfficeManualBookingController;
use App\Http\Controllers\Api\FrontOffice\PhotographerAssignmentController as FrontOfficePhotographerAssignmentController;
use App\Http\Controllers\Api\FrontOffice\CalendarController as FrontOfficeCalendarController;
use App\Http\Controllers\Api\FrontOffice\ProgressMonitoringController as FrontOfficeProgressMonitoringController;
use App\Http\Controllers\Api\FrontOffice\FinanceController as FrontOfficeFinanceController;
use App\Http\Controllers\Api\FrontOffice\EditAssignmentController as FrontOfficeEditAssignmentController;
use App\Http\Controllers\Api\FrontOffice\PrintOrderController as FrontOfficePrintOrderController;


/*
|--------------------------------------------------------------------------
| Public API
|--------------------------------------------------------------------------
*/

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

/*
|--------------------------------------------------------------------------
| Midtrans Callback
|--------------------------------------------------------------------------
| Callback Midtrans jangan ditaruh hanya di auth:sanctum, karena Midtrans
| tidak membawa token login user. Cukup satu route notification.
|--------------------------------------------------------------------------
*/

Route::post('/midtrans/notification', [MidtransNotificationController::class, 'handle'])
    ->name('api.midtrans.notification');

/*
|--------------------------------------------------------------------------
| Protected API
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    /*
    |--------------------------------------------------------------------------
    | CLIENT / KLIEN
    |--------------------------------------------------------------------------
    */

    Route::middleware('role.api:Klien')->group(function () {
        /*
        |--------------------------------------------------------------------------
        | Package
        |--------------------------------------------------------------------------
        */

        Route::get('/packages', [PackageController::class, 'index']);
        Route::get('/packages/{package}', [PackageController::class, 'show']);

        /*
        |--------------------------------------------------------------------------
        | Schedule
        |--------------------------------------------------------------------------
        */

        Route::get('/schedules', [ScheduleController::class, 'index']);

        /*
        |--------------------------------------------------------------------------
        | Booking
        |--------------------------------------------------------------------------
        */

        Route::get('/bookings', [BookingController::class, 'index']);
        Route::get('/bookings/{booking}', [BookingController::class, 'show']);
        Route::post('/bookings', [BookingController::class, 'store']);

        /*
        |--------------------------------------------------------------------------
        | Booking Payment
        |--------------------------------------------------------------------------
        */

        Route::post('/bookings/{booking}/payments', [BookingPaymentController::class, 'createSnap']);
        Route::post('/bookings/{booking}/payments/check-status', [MidtransPaymentSyncController::class, 'checkBookingPayment']);

        /*
        |--------------------------------------------------------------------------
        | Booking Addon
        |--------------------------------------------------------------------------
        */

        Route::get('/booking-addon-settings', [BookingAddonSettingController::class, 'index']);

        /*
        |--------------------------------------------------------------------------
        | Tracking
        |--------------------------------------------------------------------------
        */

        Route::get('/tracking/{booking}', [TrackingController::class, 'show']);

        /*
        |--------------------------------------------------------------------------
        | Photo Link
        |--------------------------------------------------------------------------
        */

        Route::get('/photo-links/{booking}', [ClientPhotoLinkController::class, 'show']);

        /*
        |--------------------------------------------------------------------------
        | Edit Request
        |--------------------------------------------------------------------------
        | Klien mengirim list nama file foto yang ingin diedit.
        |--------------------------------------------------------------------------
        */

        Route::get('/edit-requests/{booking}', [ClientEditRequestController::class, 'show']);
        Route::post('/edit-requests', [ClientEditRequestController::class, 'store']);

        /*
        |--------------------------------------------------------------------------
        | Print Order
        |--------------------------------------------------------------------------
        | Alur cetak klien:
        | - ambil harga cetak
        | - lihat order cetak booking
        | - buat order cetak
        | - skip cetak
        | - bayar cetak
        |--------------------------------------------------------------------------
        */

        Route::get('/print-prices', [ClientPrintOrderController::class, 'prices']);
        Route::get('/bookings/{booking}/print-order', [ClientPrintOrderController::class, 'show']);
        Route::post('/print-orders', [ClientPrintOrderController::class, 'store']);
        Route::post('/bookings/{booking}/print-order/skip', [ClientPrintOrderController::class, 'skip']);
        Route::post('/print-orders/{printOrder}/payments', [ClientPrintPaymentController::class, 'create']);
        Route::post('/print-orders/{printOrder}/payments/check-status', [MidtransPaymentSyncController::class, 'checkPrintPayment']);

        /*
        |--------------------------------------------------------------------------
        | Review
        |--------------------------------------------------------------------------
        */

        Route::get('/reviews/{booking}', [ClientReviewController::class, 'show']);
        Route::post('/reviews', [ClientReviewController::class, 'store']);

        /*
        |--------------------------------------------------------------------------
        | Call Center / Contact
        |--------------------------------------------------------------------------
        */

        Route::get('/call-center-contacts', [ClientCallCenterContactController::class, 'index']);
    });

    /*
    |--------------------------------------------------------------------------
    | PHOTOGRAPHER / FOTOGRAFER
    |--------------------------------------------------------------------------
    */

    Route::prefix('photographer')->middleware('role.api:Fotografer')->group(function () {
        Route::get('/bookings', [PhotographerAssignedBookingController::class, 'index']);
        Route::get('/bookings/{booking}', [PhotographerAssignedBookingController::class, 'show']);
        Route::post('/photo-links', [PhotographerPhotoLinkController::class, 'store']);
    });

    /*
    |--------------------------------------------------------------------------
    | EDITOR
    |--------------------------------------------------------------------------
    */

    Route::prefix('editor')->middleware('role.api:Editor')->group(function () {
        Route::get('/edit-requests', [EditorEditRequestController::class, 'index']);
        Route::get('/edit-requests/{editRequest}', [EditorEditRequestController::class, 'show']);
        Route::patch('/edit-requests/{editRequest}/start', [EditorEditRequestController::class, 'start']);
        Route::patch('/edit-requests/{editRequest}/complete', [EditorEditRequestController::class, 'complete']);
    });

    /*
    |--------------------------------------------------------------------------
    | FRONT OFFICE
    |--------------------------------------------------------------------------
    */

    Route::prefix('front-office')->middleware('role.api:Front Office')->group(function () {
        /*
        |--------------------------------------------------------------------------
        | Manual Booking
        |--------------------------------------------------------------------------
        */

        Route::get('/packages', [FrontOfficeManualBookingController::class, 'packages']);
        Route::get('/packages/{package}', [FrontOfficeManualBookingController::class, 'packageShow']);
        Route::get('/available-slots', [FrontOfficeManualBookingController::class, 'availableSlots']);
        Route::get('/addon-settings', [FrontOfficeManualBookingController::class, 'addonSettings']);
        Route::post('/bookings/manual', [FrontOfficeManualBookingController::class, 'store']);

        /*
        |--------------------------------------------------------------------------
        | Assign Photographer
        |--------------------------------------------------------------------------
        */

        Route::get('/bookings/assignable', [FrontOfficePhotographerAssignmentController::class, 'assignableBookings']);
        Route::get('/bookings/{booking}/available-photographers', [FrontOfficePhotographerAssignmentController::class, 'availablePhotographers']);
        Route::patch('/bookings/{booking}/assign-photographer', [FrontOfficePhotographerAssignmentController::class, 'assign']);

        /*
        |--------------------------------------------------------------------------
        | Assign Editor
        |--------------------------------------------------------------------------
        */

        Route::get('/edit-requests', [FrontOfficeEditAssignmentController::class, 'index']);
        Route::get('/edit-requests/{editRequest}', [FrontOfficeEditAssignmentController::class, 'show']);
        Route::get('/editors', [FrontOfficeEditAssignmentController::class, 'editors']);
        Route::patch('/edit-requests/{editRequest}/assign-editor', [FrontOfficeEditAssignmentController::class, 'assign']);

        /*
        |--------------------------------------------------------------------------
        | Calendar
        |--------------------------------------------------------------------------
        */

        Route::get('/calendar', [FrontOfficeCalendarController::class, 'index']);

        /*
        |--------------------------------------------------------------------------
        | Progress Monitoring
        |--------------------------------------------------------------------------
        */

        Route::get('/progress', [FrontOfficeProgressMonitoringController::class, 'index']);
        Route::get('/progress/{booking}', [FrontOfficeProgressMonitoringController::class, 'show']);

        /*
        |--------------------------------------------------------------------------
        | Print Order
        |--------------------------------------------------------------------------
        | Front Office memproses order cetak yang sudah dibayar.
        |--------------------------------------------------------------------------
        */

        Route::get('/print-orders', [FrontOfficePrintOrderController::class, 'index']);
        Route::get('/print-orders/{printOrder}', [FrontOfficePrintOrderController::class, 'show']);
        Route::patch('/print-orders/{printOrder}/process', [FrontOfficePrintOrderController::class, 'markProcessing']);
        Route::post('/print-orders/{printOrder}/complete', [FrontOfficePrintOrderController::class, 'complete']);

        /*
        |--------------------------------------------------------------------------
        | Finance
        |--------------------------------------------------------------------------
        */

        Route::get('/finance/summary', [FrontOfficeFinanceController::class, 'summary']);
        Route::get('/expenses', [FrontOfficeFinanceController::class, 'expenses']);
        Route::post('/expenses', [FrontOfficeFinanceController::class, 'storeExpense']);
    });
});
