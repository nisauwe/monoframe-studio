@echo off

mkdir lib\core\config
mkdir lib\core\constants
mkdir lib\core\theme
mkdir lib\core\utils

mkdir lib\data\models
mkdir lib\data\services
mkdir lib\data\providers

mkdir lib\presentation\screens\splash
mkdir lib\presentation\screens\auth
mkdir lib\presentation\screens\home
mkdir lib\presentation\screens\package
mkdir lib\presentation\screens\booking
mkdir lib\presentation\screens\payment
mkdir lib\presentation\screens\tracking
mkdir lib\presentation\screens\gallery
mkdir lib\presentation\screens\print
mkdir lib\presentation\screens\review
mkdir lib\presentation\screens\profile

mkdir lib\presentation\widgets

type nul > lib\main.dart

type nul > lib\core\config\app_config.dart
type nul > lib\core\config\api_config.dart

type nul > lib\core\constants\app_colors.dart
type nul > lib\core\constants\app_texts.dart
type nul > lib\core\constants\app_assets.dart

type nul > lib\core\theme\app_theme.dart

type nul > lib\core\utils\currency_formatter.dart
type nul > lib\core\utils\date_formatter.dart

type nul > lib\data\models\user_model.dart
type nul > lib\data\models\package_model.dart
type nul > lib\data\models\booking_model.dart
type nul > lib\data\models\tracking_model.dart
type nul > lib\data\models\review_model.dart

type nul > lib\data\services\dio_client.dart
type nul > lib\data\services\auth_service.dart
type nul > lib\data\services\package_service.dart
type nul > lib\data\services\booking_service.dart
type nul > lib\data\services\payment_service.dart
type nul > lib\data\services\tracking_service.dart
type nul > lib\data\services\print_service.dart
type nul > lib\data\services\review_service.dart

type nul > lib\data\providers\auth_provider.dart
type nul > lib\data\providers\package_provider.dart
type nul > lib\data\providers\booking_provider.dart
type nul > lib\data\providers\tracking_provider.dart
type nul > lib\data\providers\review_provider.dart

type nul > lib\presentation\widgets\custom_button.dart
type nul > lib\presentation\widgets\custom_text_field.dart
type nul > lib\presentation\widgets\package_card.dart
type nul > lib\presentation\widgets\tracking_stepper.dart
type nul > lib\presentation\widgets\empty_state.dart

echo Struktur folder dan file berhasil dibuat.
pause