import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/monoframe_logo_mark.dart';
import '../role/role_gate_screen.dart';

class AuthLoginBottomSheet extends StatefulWidget {
  final VoidCallback onOpenRegister;

  const AuthLoginBottomSheet({super.key, required this.onOpenRegister});

  @override
  State<AuthLoginBottomSheet> createState() => _AuthLoginBottomSheetState();
}

class _AuthLoginBottomSheetState extends State<AuthLoginBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool rememberMe = true;
  String? loginError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _clearLoginError() {
    if (loginError != null) {
      setState(() => loginError = null);
    }
  }

  Future<void> submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loginError = null);

    final success = await context.read<AuthProvider>().login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (success) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleGateScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        loginError = authProvider.errorMessage ?? 'Email atau password salah.';
      });
    }
  }

  void openForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => const ForgotPasswordBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 14),

                  const _AuthHeader(
                    title: 'Welcome Back',
                    subtitle: 'Masuk ke akun Monoframe kamu.',
                  ),

                  if (loginError != null) ...[
                    const SizedBox(height: 18),
                    _InlineAuthMessage(
                      message: loginError!,
                      type: _InlineAuthMessageType.error,
                    ),
                  ],

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearLoginError(),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'nama@email.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: _emailValidator,
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _clearLoginError(),
                    onFieldSubmitted: (_) => submitLogin(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        activeColor: AppColors.primaryDark,
                        onChanged: authProvider.isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  rememberMe = value ?? true;
                                });
                              },
                      ),
                      const Expanded(
                        child: Text(
                          'Ingat saya',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : openForgotPassword,
                        child: const Text('Lupa password?'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _PrimaryAuthButton(
                    text: 'Log In',
                    isLoading: authProvider.isLoading,
                    onPressed: submitLogin,
                  ),

                  const SizedBox(height: 18),

                  _AuthSwitchAction(
                    message: 'Belum punya akun?',
                    actionText: 'Create Account',
                    onTap: authProvider.isLoading
                        ? null
                        : widget.onOpenRegister,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthRegisterBottomSheet extends StatefulWidget {
  final VoidCallback onOpenLogin;

  const AuthRegisterBottomSheet({super.key, required this.onOpenLogin});

  @override
  State<AuthRegisterBottomSheet> createState() =>
      _AuthRegisterBottomSheetState();
}

class _AuthRegisterBottomSheetState extends State<AuthRegisterBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final otpController = TextEditingController();

  final usernameController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agree = true;
  bool otpSent = false;

  String? registerError;
  String? registerSuccess;
  String? otpError;
  String? otpSuccess;

  @override
  void dispose() {
    otpController.dispose();
    usernameController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearRegisterMessages() {
    if (registerError != null ||
        registerSuccess != null ||
        otpError != null ||
        otpSuccess != null) {
      setState(() {
        registerError = null;
        registerSuccess = null;
        otpError = null;
        otpSuccess = null;
      });
    }
  }

  Future<void> requestOtp() async {
    _clearRegisterMessages();

    if (!_formKey.currentState!.validate()) {
      setState(() {
        registerError = 'Periksa kembali data registrasi yang masih salah.';
      });
      return;
    }

    if (!agree) {
      setState(() {
        registerError = 'Setujui syarat layanan terlebih dahulu.';
      });
      return;
    }

    final success = await context.read<AuthProvider>().requestRegisterOtp(
      name: nameController.text.trim(),
      username: usernameController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (success) {
      setState(() {
        otpSent = true;
        registerError = null;
        registerSuccess = null;
        otpError = null;
        otpSuccess =
            authProvider.successMessage ??
            'Kode OTP sudah dikirim ke email. Silakan cek inbox atau spam.';
      });
    } else {
      setState(() {
        registerError =
            authProvider.errorMessage ??
            'Registrasi gagal. Periksa username, email, dan data lainnya.';
      });
    }
  }

  Future<void> verifyOtpAndRegister() async {
    final otp = otpController.text.trim();

    setState(() {
      otpError = null;
      otpSuccess = null;
    });

    if (otp.isEmpty) {
      setState(() {
        otpError = 'Kode OTP wajib diisi.';
      });
      return;
    }

    if (otp.length != 6) {
      setState(() {
        otpError = 'Masukkan kode OTP 6 digit.';
      });
      return;
    }

    final success = await context.read<AuthProvider>().verifyRegisterOtp(
      email: emailController.text.trim(),
      otp: otp,
    );

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (success) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleGateScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        otpError = authProvider.errorMessage ?? 'Verifikasi OTP gagal.';
      });
    }
  }

  void backToForm() {
    setState(() {
      otpSent = false;
      otpError = null;
      otpSuccess = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: otpSent
                ? _RegisterOtpContent(
                    email: emailController.text.trim(),
                    otpController: otpController,
                    isLoading: authProvider.isLoading,
                    errorMessage: otpError,
                    successMessage: otpSuccess,
                    onChanged: _clearRegisterMessages,
                    onBack: backToForm,
                    onResend: requestOtp,
                    onVerify: verifyOtpAndRegister,
                    onOpenLogin: authProvider.isLoading
                        ? null
                        : widget.onOpenLogin,
                  )
                : _RegisterFormContent(
                    formKey: _formKey,
                    authProvider: authProvider,
                    usernameController: usernameController,
                    nameController: nameController,
                    phoneController: phoneController,
                    addressController: addressController,
                    emailController: emailController,
                    passwordController: passwordController,
                    confirmPasswordController: confirmPasswordController,
                    obscurePassword: obscurePassword,
                    obscureConfirmPassword: obscureConfirmPassword,
                    agree: agree,
                    errorMessage: registerError,
                    successMessage: registerSuccess,
                    onChanged: _clearRegisterMessages,
                    onAgreeChanged: (value) {
                      setState(() {
                        agree = value ?? false;
                        registerError = null;
                      });
                    },
                    onTogglePassword: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    onToggleConfirmPassword: () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
                    onSubmit: requestOtp,
                    onOpenLogin: authProvider.isLoading
                        ? null
                        : widget.onOpenLogin,
                  ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordBottomSheet extends StatefulWidget {
  const ForgotPasswordBottomSheet({super.key});

  @override
  State<ForgotPasswordBottomSheet> createState() =>
      _ForgotPasswordBottomSheetState();
}

class _ForgotPasswordBottomSheetState extends State<ForgotPasswordBottomSheet> {
  final emailFormKey = GlobalKey<FormState>();
  final resetFormKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool otpSent = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String? forgotError;
  String? forgotSuccess;

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearForgotMessages() {
    if (forgotError != null || forgotSuccess != null) {
      setState(() {
        forgotError = null;
        forgotSuccess = null;
      });
    }
  }

  Future<void> requestOtp() async {
    _clearForgotMessages();

    if (!emailFormKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().requestPasswordResetOtp(
      email: emailController.text.trim(),
    );

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (success) {
      setState(() {
        otpSent = true;
        forgotError = null;
        forgotSuccess =
            authProvider.successMessage ??
            'Kode OTP reset password sudah dikirim ke email.';
      });
    } else {
      setState(() {
        forgotError = authProvider.errorMessage ?? 'Gagal mengirim OTP.';
      });
    }
  }

  Future<void> resetPassword() async {
    _clearForgotMessages();

    if (!resetFormKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().resetPasswordWithOtp(
      email: emailController.text.trim(),
      otp: otpController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (success) {
      setState(() {
        forgotError = null;
        forgotSuccess =
            authProvider.successMessage ?? 'Password berhasil diganti.';
      });

      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      setState(() {
        forgotError = authProvider.errorMessage ?? 'Reset password gagal.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: otpSent
                ? Form(
                    key: resetFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetHandle(),
                        const SizedBox(height: 14),
                        _AuthHeader(
                          title: 'Reset Password',
                          subtitle:
                              'Masukkan OTP yang dikirim ke ${emailController.text.trim()}, lalu buat password baru.',
                        ),

                        if (forgotError != null) ...[
                          const SizedBox(height: 18),
                          _InlineAuthMessage(
                            message: forgotError!,
                            type: _InlineAuthMessageType.error,
                          ),
                        ],

                        if (forgotSuccess != null) ...[
                          const SizedBox(height: 18),
                          _InlineAuthMessage(
                            message: forgotSuccess!,
                            type: _InlineAuthMessageType.success,
                          ),
                        ],

                        const SizedBox(height: 24),

                        _OtpField(
                          controller: otpController,
                          onChanged: _clearForgotMessages,
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => _clearForgotMessages(),
                          decoration: InputDecoration(
                            labelText: 'Password Baru',
                            hintText: 'Minimal 8 karakter',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: _passwordValidator,
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => _clearForgotMessages(),
                          onFieldSubmitted: (_) => resetPassword(),
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Password Baru',
                            hintText: 'Ulangi password baru',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Konfirmasi password wajib diisi';
                            }

                            if (value != passwordController.text) {
                              return 'Konfirmasi password tidak sama';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        _PrimaryAuthButton(
                          text: 'Reset Password',
                          isLoading: authProvider.isLoading,
                          onPressed: resetPassword,
                        ),

                        const SizedBox(height: 10),

                        Center(
                          child: TextButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : requestOtp,
                            child: const Text('Kirim ulang OTP'),
                          ),
                        ),
                      ],
                    ),
                  )
                : Form(
                    key: emailFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetHandle(),
                        const SizedBox(height: 14),

                        const _AuthHeader(
                          title: 'Lupa Password',
                          subtitle:
                              'Masukkan email akun Monoframe kamu. Kami akan mengirim kode OTP untuk reset password.',
                        ),

                        if (forgotError != null) ...[
                          const SizedBox(height: 18),
                          _InlineAuthMessage(
                            message: forgotError!,
                            type: _InlineAuthMessageType.error,
                          ),
                        ],

                        if (forgotSuccess != null) ...[
                          const SizedBox(height: 18),
                          _InlineAuthMessage(
                            message: forgotSuccess!,
                            type: _InlineAuthMessageType.success,
                          ),
                        ],

                        const SizedBox(height: 24),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => _clearForgotMessages(),
                          onFieldSubmitted: (_) => requestOtp(),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'nama@email.com',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: _emailValidator,
                        ),

                        const SizedBox(height: 18),

                        _PrimaryAuthButton(
                          text: 'Kirim OTP',
                          isLoading: authProvider.isLoading,
                          onPressed: requestOtp,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RegisterFormContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final AuthProvider authProvider;
  final TextEditingController usernameController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool agree;
  final String? errorMessage;
  final String? successMessage;
  final VoidCallback onChanged;
  final ValueChanged<bool?> onAgreeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;
  final VoidCallback? onOpenLogin;

  const _RegisterFormContent({
    required this.formKey,
    required this.authProvider,
    required this.usernameController,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.agree,
    required this.errorMessage,
    required this.successMessage,
    required this.onChanged,
    required this.onAgreeChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
    required this.onOpenLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 14),

          const _AuthHeader(
            title: 'Create Account',
            subtitle: 'Daftar sebagai klien Monoframe Studio.',
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 18),
            _InlineAuthMessage(
              message: errorMessage!,
              type: _InlineAuthMessageType.error,
            ),
          ],

          if (successMessage != null) ...[
            const SizedBox(height: 18),
            _InlineAuthMessage(
              message: successMessage!,
              type: _InlineAuthMessageType.success,
            ),
          ],

          const SizedBox(height: 24),

          TextFormField(
            controller: usernameController,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'contoh: monoframeuser',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Username wajib diisi';
              }

              return null;
            },
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              hintText: 'Masukkan nama lengkap',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Nama wajib diisi';
              }

              return null;
            },
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Nomor WhatsApp',
              hintText: '08xxxxxxxxxx',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Nomor WhatsApp wajib diisi';
              }

              return null;
            },
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'nama@email.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: _emailValidator,
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: addressController,
            minLines: 2,
            maxLines: 3,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Alamat',
              hintText: 'Alamat lengkap',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Alamat wajib diisi';
              }

              return null;
            },
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Minimal 8 karakter',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            validator: _passwordValidator,
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: confirmPasswordController,
            obscureText: obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onChanged: (_) => onChanged(),
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: 'Konfirmasi Password',
              hintText: 'Ulangi password',
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                onPressed: onToggleConfirmPassword,
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            validator: (value) {
              if ((value ?? '').isEmpty) {
                return 'Konfirmasi password wajib diisi';
              }

              if (value != passwordController.text) {
                return 'Konfirmasi password tidak sama';
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          CheckboxListTile(
            value: agree,
            onChanged: authProvider.isLoading ? null : onAgreeChanged,
            activeColor: AppColors.primaryDark,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Saya menyetujui syarat layanan Monoframe Studio.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 12),

          _PrimaryAuthButton(
            text: 'Kirim OTP Email',
            isLoading: authProvider.isLoading,
            onPressed: onSubmit,
          ),

          const SizedBox(height: 18),

          _AuthSwitchAction(
            message: 'Sudah punya akun?',
            actionText: 'Log In',
            onTap: onOpenLogin,
          ),
        ],
      ),
    );
  }
}

class _RegisterOtpContent extends StatelessWidget {
  final String email;
  final TextEditingController otpController;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final VoidCallback onChanged;
  final VoidCallback onBack;
  final VoidCallback onResend;
  final VoidCallback onVerify;
  final VoidCallback? onOpenLogin;

  const _RegisterOtpContent({
    required this.email,
    required this.otpController,
    required this.isLoading,
    required this.errorMessage,
    required this.successMessage,
    required this.onChanged,
    required this.onBack,
    required this.onResend,
    required this.onVerify,
    required this.onOpenLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SheetHandle(),
        const SizedBox(height: 14),

        _AuthHeader(
          title: 'Verifikasi Email',
          subtitle: 'Kode OTP sudah dikirim ke $email. Cek inbox atau spam.',
        ),

        if (errorMessage != null) ...[
          const SizedBox(height: 18),
          _InlineAuthMessage(
            message: errorMessage!,
            type: _InlineAuthMessageType.error,
          ),
        ],

        if (successMessage != null) ...[
          const SizedBox(height: 18),
          _InlineAuthMessage(
            message: successMessage!,
            type: _InlineAuthMessageType.success,
          ),
        ],

        const SizedBox(height: 24),

        _OtpField(controller: otpController, onChanged: onChanged),

        const SizedBox(height: 18),

        _PrimaryAuthButton(
          text: 'Verifikasi & Buat Akun',
          isLoading: isLoading,
          onPressed: onVerify,
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: isLoading ? null : onBack,
                child: const Text('Ubah data'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: isLoading ? null : onResend,
                child: const Text('Kirim ulang OTP'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        _AuthSwitchAction(
          message: 'Sudah punya akun?',
          actionText: 'Log In',
          onTap: onOpenLogin,
        ),
      ],
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AuthHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const MonoframeLogoMark(size: 58),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;

  const _OtpField({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textInputAction: TextInputAction.done,
      textAlign: TextAlign.center,
      onChanged: (_) => onChanged?.call(),
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 8,
        color: AppColors.primaryDark,
      ),
      decoration: const InputDecoration(
        counterText: '',
        labelText: 'Kode OTP',
        hintText: '------',
        prefixIcon: Icon(Icons.verified_user_outlined),
      ),
      validator: (value) {
        final otp = value?.trim() ?? '';

        if (otp.isEmpty) return 'Kode OTP wajib diisi';

        if (otp.length != 6) return 'Kode OTP harus 6 digit';

        return null;
      },
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryAuthButton({
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _AuthSwitchAction extends StatelessWidget {
  final String message;
  final String actionText;
  final VoidCallback? onTap;

  const _AuthSwitchAction({
    required this.message,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Text(
                  actionText,
                  style: TextStyle(
                    color: onTap == null
                        ? AppColors.grey.withOpacity(0.55)
                        : AppColors.primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _InlineAuthMessageType { error, success }

class _InlineAuthMessage extends StatelessWidget {
  final String message;
  final _InlineAuthMessageType type;

  const _InlineAuthMessage({required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    final isError = type == _InlineAuthMessageType.error;

    final backgroundColor = isError
        ? const Color(0xFFFFEEF0)
        : const Color(0xFFEFFAF3);

    final borderColor = isError
        ? const Color(0xFFFFC9D1)
        : const Color(0xFFBCE9C9);

    final textColor = isError
        ? const Color(0xFFE11D48)
        : const Color(0xFF16803D);

    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';

  if (email.isEmpty) return 'Email wajib diisi';

  if (!email.contains('@')) return 'Format email tidak valid';

  return null;
}

String? _passwordValidator(String? value) {
  final password = value ?? '';

  if (password.isEmpty) return 'Password wajib diisi';

  if (password.length < 8) return 'Password minimal 8 karakter';

  return null;
}
