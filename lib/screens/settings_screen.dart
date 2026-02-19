import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../utils/accessibility_helpers.dart';

/// 設定画面
///
/// - 文字サイズスライダー（3段階: 大/特大/最大）
/// - プレビューテキスト（スライダー操作でリアルタイム変化）
/// - コントラスト切替（ラジオボタン2択）
/// - 変更は即座に ObjectBox 保存・UI に反映
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return _buildContent(context, ref, settings);
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final theme = Theme.of(context);
    final isHighContrast = settings.isHighContrast;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Semantics(
          label: AccessibilityLabels.goBack,
          button: true,
          child: SizedBox(
            width: 64,
            height: 64,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              iconSize: 28,
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          'せってい',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFontSizeSection(context, ref, settings, isHighContrast),
            const SizedBox(height: 8),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            _buildContrastSection(context, ref, settings, theme, isHighContrast),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // 文字の大きさセクション
  // -------------------------

  Widget _buildFontSizeSection(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    bool isHighContrast,
  ) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('文字の大きさ', style: labelStyle),
        const SizedBox(height: 16),
        Semantics(
          label: '文字の大きさ（大から最大を選べます）',
          slider: true,
          child: Slider(
            value: settings.fontSize,
            min: 1.0,
            max: 3.0,
            divisions: 2,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateFontSize(value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sizeLabel('大', settings.fontSize == 1.0, theme),
            _sizeLabel('特大', settings.fontSize == 2.0, theme),
            _sizeLabel('最大', settings.fontSize == 3.0, theme),
          ],
        ),
        const SizedBox(height: 20),
        Semantics(
          label: 'このサイズで表示されます',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isHighContrast
                    ? const Color(0xFFFFFF00)
                    : Colors.grey.shade400,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'この大きさで\n表示されます',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: resolveBodyFontSize(settings.fontSize),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sizeLabel(String label, bool isSelected, ThemeData theme) {
    return Text(
      label,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // -------------------------
  // 画面の色セクション
  // -------------------------

  Widget _buildContrastSection(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    ThemeData theme,
    bool isHighContrast,
  ) {
    final labelStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('画面の色', style: labelStyle),
        const SizedBox(height: 8),
        RadioGroup<bool>(
          groupValue: settings.isHighContrast,
          onChanged: (value) {
            if (value != null) {
              ref
                  .read(settingsProvider.notifier)
                  .toggleHighContrast(value);
            }
          },
          child: Column(
            children: [
              Semantics(
                label: '白い画面',
                child: RadioListTile<bool>(
                  title: Text(
                    '白い画面',
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20),
                  ),
                  value: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Semantics(
                label: '黒い画面、見やすい',
                child: RadioListTile<bool>(
                  title: Text(
                    '黒い画面（見やすい）',
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20),
                  ),
                  value: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
