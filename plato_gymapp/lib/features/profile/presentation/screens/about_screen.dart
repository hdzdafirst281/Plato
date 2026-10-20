import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_bar.dart';
import 'package:plato_gymapp/features/notifications/presentation/screens/notification_diagnostics_screen.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _versionTapCount = 0;
  DateTime? _lastVersionTapAt;

  void _handleVersionTap() {
    final now = DateTime.now();
    if (_lastVersionTapAt == null ||
        now.difference(_lastVersionTapAt!) > const Duration(seconds: 5)) {
      _versionTapCount = 0;
    }
    _lastVersionTapAt = now;
    _versionTapCount++;
    if (_versionTapCount < 7) return;
    _versionTapCount = 0;
    _lastVersionTapAt = null;
    Navigator.of(context, rootNavigator: false).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationDiagnosticsScreen(),
      ),
    );
  }

  void _sendSupportEmail() async {
    final subjectText = t.settings.msg_intent_email_subject;
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support.plato@zenithas.vn',
      query: 'subject=${Uri.encodeComponent(subjectText)}',
    );

    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Không thể mở ứng dụng Email');
    }
  }

  void _launchSocialUrl(String webUrl, {String? nativeUrl}) async {
    if (webUrl.isEmpty) return;

    if (nativeUrl != null && nativeUrl.isNotEmpty) {
      final Uri nativeUri = Uri.parse(nativeUrl);
      try {
        if (await launchUrl(nativeUri, mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (e) {
        debugPrint('Lỗi mở nativeUrl: $e');
      }
    }

    final Uri webUri = Uri.parse(webUrl);
    try {
      if (await launchUrl(
        webUri,
        mode: LaunchMode.externalNonBrowserApplication,
      )) {
        return;
      }
    } catch (e) {
      debugPrint('Lỗi mở externalNonBrowserApplication: $e');
    }

    if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
      debugPrint('Không thể mở liên kết: $webUrl');
    }
  }

  Widget _buildSocialIcon(
    Widget iconWidget,
    ColorScheme colorScheme,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        child: Center(child: iconWidget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.settings.title_about_screen,
        onBackClick: () => context.pop(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              const SizedBox(height: 16),
              // Brand logo & title header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/logo/logo_plato.png',
                        width: 80,
                        height: 80,
                        cacheWidth: 160,
                        cacheHeight: 160,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.app_name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.settings.desc_about_plato,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'v1.1.1',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Contact & Support
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.mail),
                title: Text(
                  t.settings.lbl_item_contact,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text("support.plato@zenithas.vn"),
                trailing: const Icon(Symbols.chevron_right),
                onTap: _sendSupportEmail,
              ),
              const Divider(height: 1),

              // Terms of Use
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.description),
                title: Text(
                  t.onboarding.lbl_terms_link,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(t.settings.desc_terms_link),
                trailing: const Icon(Symbols.chevron_right),
                onTap: () => _showTermsDialog(context),
              ),
              const Divider(height: 1),

              // EULA
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.contract),
                title: Text(
                  t.onboarding.lbl_eula_link,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(t.settings.desc_eula_link),
                trailing: const Icon(Symbols.chevron_right),
                onTap: () => _showEulaDialog(context),
              ),
              const Divider(height: 1),

              // Version (Diagnostics accessible on tap)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.info),
                title: Text(
                  t.settings.lbl_item_version,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text("1.1.1"),
                onTap: _handleVersionTap,
              ),

              const SizedBox(height: 40),

              // Social Links Section
              Center(
                child: Column(
                  children: [
                    Text(
                      t.common.about_us,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialIcon(
                          FaIcon(
                            FontAwesomeIcons.instagram,
                            size: 22,
                            color: colorScheme.onSurface,
                          ),
                          colorScheme,
                          () => _launchSocialUrl(
                            'https://www.instagram.com/plato.zenithas/',
                            nativeUrl: 'instagram://user?username=plato.zenithas',
                          ),
                        ),
                        const SizedBox(width: 20),
                        _buildSocialIcon(
                          FaIcon(
                            FontAwesomeIcons.facebookF,
                            size: 22,
                            color: colorScheme.onSurface,
                          ),
                          colorScheme,
                          () => _launchSocialUrl(
                            'https://www.facebook.com/profile.php?id=61592005979928',
                            nativeUrl: 'fb://profile/61592005979928',
                          ),
                        ),
                        const SizedBox(width: 20),
                        _buildSocialIcon(
                          FaIcon(
                            FontAwesomeIcons.threads,
                            size: 22,
                            color: colorScheme.onSurface,
                          ),
                          colorScheme,
                          () => _launchSocialUrl(
                            'https://www.threads.com/@plato.zenithas',
                          ),
                        ),
                        const SizedBox(width: 20),
                        _buildSocialIcon(
                          FaIcon(
                            FontAwesomeIcons.tiktok,
                            size: 22,
                            color: colorScheme.onSurface,
                          ),
                          colorScheme,
                          () => _launchSocialUrl(
                            'https://www.tiktok.com/@plato.zenithas?_r=1&_t=ZS-990YzsfNfXO',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

List<TextSpan> _buildRichSpans(String text, ColorScheme colorScheme) {
  final String appName = t.app_name;
  final String brandName = t.company_name;
  final List<TextSpan> spans = [];

  final regex = RegExp(r'(\{app\}|\{brand\})');
  final matches = regex.allMatches(text);

  int lastIndex = 0;
  for (final match in matches) {
    if (match.start > lastIndex) {
      spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
    }
    final tag = match.group(0);
    if (tag == '{app}') {
      spans.add(
        TextSpan(
          text: appName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      );
    } else if (tag == '{brand}') {
      spans.add(
        TextSpan(
          text: brandName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      );
    }
    lastIndex = match.end;
  }
  if (lastIndex < text.length) {
    spans.add(TextSpan(text: text.substring(lastIndex)));
  }
  return spans;
}

void _showTermsDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  GymDialog.showCustom(
    context: context,
    useRootNavigator: false,
    titleWidget: RichText(
      text: TextSpan(
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 20,
          color: colorScheme.onSurface,
        ),
        children: _buildRichSpans(
          t.onboarding.title_terms(app: "{app}"),
          colorScheme,
        ),
      ),
    ),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTermsSection(t.onboarding.terms_p1_title, [
          t.onboarding.terms_p1_desc1(app: "{app}"),
          t.onboarding.terms_p1_desc2,
          t.onboarding.terms_p1_desc3(app: "{app}"),
        ], colorScheme),
        _buildTermsSection(t.onboarding.terms_p2_title, [
          t.onboarding.terms_p2_desc1,
          t.onboarding.terms_p2_desc2,
          t.onboarding.terms_p2_desc3,
        ], colorScheme),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
        child: Text(t.common.close),
      ),
    ],
  );
}

void _showEulaDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  GymDialog.showCustom(
    context: context,
    useRootNavigator: false,
    titleWidget: RichText(
      text: TextSpan(
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: colorScheme.onSurface,
        ),
        children: _buildRichSpans(
          t.onboarding.title_eula(app: "{app}"),
          colorScheme,
        ),
      ),
    ),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.onboarding.eula_updated,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
            children: _buildRichSpans(
              t.onboarding.eula_intro(app: "{app}", brand: "{brand}"),
              colorScheme,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTermsSection(t.onboarding.eula_p1_title, [
          t.onboarding.eula_p1_desc(app: "{app}"),
        ], colorScheme),
        _buildTermsSection(t.onboarding.eula_p2_title, [
          t.onboarding.eula_p2_desc1(app: "{app}"),
          t.onboarding.eula_p2_item1,
          t.onboarding.eula_p2_item2(app: "{app}", brand: "{brand}"),
          t.onboarding.eula_p2_item3,
          t.onboarding.eula_p2_desc2(brand: "{brand}"),
        ], colorScheme),
        _buildTermsSection(t.onboarding.eula_p3_title, [
          t.onboarding.eula_p3_desc1,
          t.onboarding.eula_p3_item1,
          t.onboarding.eula_p3_item2(app: "{app}"),
          t.onboarding.eula_p3_item3,
        ], colorScheme),
        _buildTermsSection(t.onboarding.eula_p4_title, [
          t.onboarding.eula_p4_desc,
        ], colorScheme),
        _buildTermsSection(t.onboarding.eula_p5_title, [
          t.onboarding.eula_p5_item1(app: "{app}"),
          t.onboarding.eula_p5_item2,
          t.onboarding.eula_p5_item3,
        ], colorScheme),
        _buildTermsSection(t.onboarding.eula_p6_title, [
          t.onboarding.eula_p6_desc,
        ], colorScheme),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
        child: Text(
          t.common.close,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ),
    ],
  );
}

Widget _buildTermsSection(
  String title,
  List<String> paragraphs,
  ColorScheme colorScheme,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 24.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...paragraphs.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
                children: _buildRichSpans(p, colorScheme),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
