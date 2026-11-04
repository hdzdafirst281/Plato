import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/di/injection.dart';
import 'package:plato_gymapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:plato_gymapp/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:plato_gymapp/features/auth/presentation/screens/auth_otp_screen.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:responsive_framework/responsive_framework.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  int? get otpCooldownTimestamp => null;

  @override
  Future<void> saveOtpCooldownTimestamp(int timestamp) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit([AuthState initialState = const AuthState()]) : super(initialState);

  @override
  void clearAuthMessage() {}

  void setAuthMessage(String? msg) {
    emit(state.copyWith(authMessage: msg));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<AuthRepository>()) {
      getIt.registerSingleton<AuthRepository>(_FakeAuthRepository());
    }
  });

  tearDownAll(() {
    getIt.reset();
  });

  Widget buildTestableWidget({required Widget child}) {
    return MaterialApp(
      builder: (context, c) => ResponsiveBreakpoints.builder(
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: 800, name: TABLET),
          Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
        ],
        child: c!,
      ),
      home: child,
    );
  }

  testWidgets('AuthOtpScreen displays 5 minutes expiration notice in Vietnamese', (tester) async {
    LocaleSettings.setLocale(AppLocale.vi);
    final authCubit = _FakeAuthCubit();

    await tester.pumpWidget(
      TranslationProvider(
        child: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: buildTestableWidget(
            child: const AuthOtpScreen(
              flowType: AuthFlowType.login,
              initialEmail: 'test@example.com',
              startAtOtpStep: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mã xác nhận có hiệu lực trong 5 phút.'), findsOneWidget);
    expect(find.byIcon(Symbols.schedule), findsOneWidget);
  });

  testWidgets('AuthOtpScreen displays 5 minutes expiration notice in English', (tester) async {
    LocaleSettings.setLocale(AppLocale.en);
    final authCubit = _FakeAuthCubit();

    await tester.pumpWidget(
      TranslationProvider(
        child: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: buildTestableWidget(
            child: const AuthOtpScreen(
              flowType: AuthFlowType.login,
              initialEmail: 'test@example.com',
              startAtOtpStep: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The verification code is valid for 5 minutes.'), findsOneWidget);
    expect(find.byIcon(Symbols.schedule), findsOneWidget);
  });

  testWidgets('AuthOtpScreen displays localized error banner for verify failed and otp expired', (tester) async {
    LocaleSettings.setLocale(AppLocale.vi);
    final authCubit = _FakeAuthCubit(const AuthState(authMessage: 'auth.err_verify_failed'));

    await tester.pumpWidget(
      TranslationProvider(
        child: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: buildTestableWidget(
            child: const AuthOtpScreen(
              flowType: AuthFlowType.login,
              initialEmail: 'test@example.com',
              startAtOtpStep: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mã xác nhận không chính xác. Vui lòng thử lại.'), findsOneWidget);

    authCubit.setAuthMessage('auth.err_otp_expired');
    await tester.pumpAndSettle();

    expect(find.text('Mã xác nhận đã hết hạn. Vui lòng gửi lại mã mới.'), findsOneWidget);

    // Switch to English
    LocaleSettings.setLocale(AppLocale.en);
    authCubit.setAuthMessage('auth.err_verify_failed');
    await tester.pumpAndSettle();

    expect(find.text('Incorrect verification code. Please try again.'), findsOneWidget);

    authCubit.setAuthMessage('auth.err_otp_expired');
    await tester.pumpAndSettle();

    expect(find.text('The verification code has expired. Please request a new code.'), findsOneWidget);
  });
}
