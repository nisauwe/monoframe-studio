import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/monoframe_logo_mark.dart';
import '../role/role_gate_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _profileKey = GlobalKey<FormState>();
  final _securityKey = GlobalKey<FormState>();

  final pageController = PageController();

  final usernameController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  int step = 0;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agree = true;

  @override
  void dispose() {
    pageController.dispose();
    usernameController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void nextStep() {
    if (step == 0 && !_profileKey.currentState!.validate()) return;
    if (step == 1 && !_securityKey.currentState!.validate()) return;

    if (step < 2) {
      setState(() => step += 1);
      pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  void previousStep() {
    if (step == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() => step -= 1);
    pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> submitRegister() async {
    if (!_profileKey.currentState!.validate()) {
      setState(() => step = 0);
      pageController.jumpToPage(0);
      return;
    }

    if (!_securityKey.currentState!.validate()) {
      setState(() => step = 1);
      pageController.jumpToPage(1);
      return;
    }

    if (!agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setujui syarat layanan terlebih dahulu.'),
        ),
      );
      return;
    }

    final success = await context.read<AuthProvider>().register(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registrasi berhasil')));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleGateScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registrasi gagal'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.primarySoft,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 20, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: authProvider.isLoading ? null : previousStep,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            color: AppColors.dark,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Lengkapi data akun klien',
                          style: TextStyle(color: AppColors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _StepIndicator(step: step),
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ProfileStep(
                    formKey: _profileKey,
                    usernameController: usernameController,
                    nameController: nameController,
                    phoneController: phoneController,
                    addressController: addressController,
                    emailController: emailController,
                  ),
                  _SecurityStep(
                    formKey: _securityKey,
                    passwordController: passwordController,
                    confirmPasswordController: confirmPasswordController,
                    obscurePassword: obscurePassword,
                    obscureConfirmPassword: obscureConfirmPassword,
                    onTogglePassword: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                    onToggleConfirm: () {
                      setState(
                        () => obscureConfirmPassword = !obscureConfirmPassword,
                      );
                    },
                  ),
                  _ReviewStep(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    passwordSet: passwordController.text.trim().isNotEmpty,
                    agree: agree,
                    onAgreeChanged: (value) => setState(() => agree = value),
                    onEditProfile: () {
                      setState(() => step = 0);
                      pageController.jumpToPage(0);
                    },
                    onEditSecurity: () {
                      setState(() => step = 1);
                      pageController.jumpToPage(1);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: authProvider.isLoading ? null : previousStep,
                      child: Text(step == 0 ? 'Login' : 'Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : step == 2
                          ? submitRegister
                          : nextStep,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(step == 2 ? 'Create Account' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;

  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.person_outline_rounded, 'Profile'),
      (Icons.lock_outline_rounded, 'Security'),
      (Icons.check_circle_outline_rounded, 'Review'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final active = index <= step;
          final isCurrent = index == step;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? AppColors.primary
                              : AppColors.primarySoft,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.30),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          active ? Icons.check_rounded : items[index].$1,
                          color: active ? Colors.white : AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        items[index].$2,
                        style: TextStyle(
                          color: active
                              ? AppColors.primaryDark
                              : AppColors.grey,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < items.length - 1)
                  Container(
                    width: 28,
                    height: 2,
                    color: index < step ? AppColors.primary : AppColors.border,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController emailController;

  const _ProfileStep({
    required this.formKey,
    required this.usernameController,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.person_outline_rounded,
      title: 'Your Profile',
      subtitle: 'Ceritakan data dasar kamu.',
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _Field(
              controller: usernameController,
              label: 'Username',
              hint: 'contoh: lokesh',
              icon: Icons.alternate_email_rounded,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Username wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _Field(
              controller: nameController,
              label: 'Nama Lengkap',
              hint: 'Masukkan nama lengkap',
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Nama wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _Field(
              controller: phoneController,
              label: 'Nomor WhatsApp',
              hint: '08xxxxxxxxxx',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if ((value ?? '').trim().isEmpty)
                  return 'Nomor WhatsApp wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _Field(
              controller: emailController,
              label: 'Email',
              hint: 'nama@email.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = (value ?? '').trim();
                if (email.isEmpty) return 'Email wajib diisi';
                if (!email.contains('@')) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _Field(
              controller: addressController,
              label: 'Alamat',
              hint: 'Alamat lengkap',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Alamat wajib diisi';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;

  const _SecurityStep({
    required this.formKey,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.lock_outline_rounded,
      title: 'Account Security',
      subtitle: 'Buat password yang aman.',
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _Field(
              controller: passwordController,
              label: 'Password',
              hint: 'Minimal 8 karakter',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) return 'Password wajib diisi';
                if (password.length < 8) return 'Password minimal 8 karakter';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _Field(
              controller: confirmPasswordController,
              label: 'Konfirmasi Password',
              hint: 'Ulangi password',
              icon: Icons.lock_reset_rounded,
              obscureText: obscureConfirmPassword,
              suffixIcon: IconButton(
                onPressed: onToggleConfirm,
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty)
                  return 'Konfirmasi password wajib diisi';
                if (value != passwordController.text) {
                  return 'Konfirmasi password tidak sama';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password harus berisi:',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 8),
                  _Requirement(text: 'Minimal 8 karakter'),
                  _Requirement(text: 'Gunakan kombinasi huruf dan angka'),
                  _Requirement(
                    text: 'Jangan gunakan password yang mudah ditebak',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final bool passwordSet;
  final bool agree;
  final ValueChanged<bool> onAgreeChanged;
  final VoidCallback onEditProfile;
  final VoidCallback onEditSecurity;

  const _ReviewStep({
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordSet,
    required this.agree,
    required this.onAgreeChanged,
    required this.onEditProfile,
    required this.onEditSecurity,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.verified_rounded,
      title: 'Almost Done!',
      subtitle: 'Periksa data akun kamu.',
      child: Column(
        children: [
          const MonoframeLogoMark(size: 86),
          const SizedBox(height: 18),
          _ReviewTile(
            icon: Icons.person_outline_rounded,
            title: 'Nama Lengkap',
            value: name.isEmpty ? 'Belum diisi' : name,
            onEdit: onEditProfile,
          ),
          _ReviewTile(
            icon: Icons.mail_outline_rounded,
            title: 'Email',
            value: email.isEmpty ? 'Belum diisi' : email,
            onEdit: onEditProfile,
          ),
          _ReviewTile(
            icon: Icons.phone_outlined,
            title: 'WhatsApp',
            value: phone.isEmpty ? 'Belum diisi' : phone,
            onEdit: onEditProfile,
          ),
          _ReviewTile(
            icon: Icons.lock_outline_rounded,
            title: 'Password',
            value: passwordSet ? 'Sudah dibuat' : 'Belum dibuat',
            onEdit: onEditSecurity,
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: agree,
            onChanged: (value) => onAgreeChanged(value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primaryDark,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Saya menyetujui syarat layanan Monoframe Studio.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _StepScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.08),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.grey)),
              const SizedBox(height: 22),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}

class _Requirement extends StatelessWidget {
  final String text;

  const _Requirement({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onEdit;

  const _ReviewTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}
