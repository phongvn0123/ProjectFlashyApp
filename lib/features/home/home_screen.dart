import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'widgets/home_header.dart';

/// Tab HOME (SCREENS §3) — dùng [HomeHeader] làm ĐẦU TRANG + thân cuộn.
///
/// Dữ liệu hiện đang là MOCK để dựng khung header/footer trước. Bước sau thay
/// bằng `homeSummaryProvider` (Riverpod) đọc local DB + API theo SCREENS §3.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false, // đáy do NavigationBar (footer) tự lo
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.xl),
        children: [
          HomeHeader(
            name: 'Trang',
            hasUnread: true,
            onBell: () => _toast(context, 'Thông báo — sắp có'),
            onAvatar: () => _toast(context, 'Hồ sơ — sắp có'),
          ),
          const SizedBox(height: Sp.xl),

          // 2 thẻ thống kê nhanh
          const Row(
            children: [
              Expanded(child: _StatCard(value: '12', label: 'Bộ thẻ')),
              SizedBox(width: Sp.sm),
              Expanded(child: _StatCard(value: '87%', label: 'Đã thuộc')),
            ],
          ),
          const SizedBox(height: Sp.xl),

          const _SectionTitle('Tiếp tục học'),
          const SizedBox(height: Sp.sm),
          const _ContinueTile(
            title: 'IELTS Vocabulary 1',
            learned: 45,
            total: 120,
          ),
          const SizedBox(height: Sp.xl),

          const _SectionTitle('Lớp của bạn'),
          const SizedBox(height: Sp.sm),
          const _ClassCard(
            name: 'Lớp 12A - Tiếng Anh',
            teacher: 'Mr. Nam',
            newItems: 3,
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// Tiêu đề nhóm nội dung (tagline 21/600).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.tagline(context));
}

/// Thẻ thống kê nhanh — store-utility-card (trắng, viền hairline, R.lg).
class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.displayMd(context)),
          const SizedBox(height: Sp.xxs),
          Text(label,
              style:
                  AppText.caption(context)?.copyWith(color: AppColors.inkMuted48)),
        ],
      ),
    );
  }
}

/// Thẻ "tiếp tục học" — product-tile-dark rút gọn để tạo nhịp sáng ↔ tối.
class _ContinueTile extends StatelessWidget {
  const _ContinueTile({
    required this.title,
    required this.learned,
    required this.total,
  });

  final String title;
  final int learned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : learned / total;
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(
        color: AppColors.tile1,
        borderRadius: BorderRadius.circular(R.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(R.sm),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.play_arrow_rounded,
                    color: AppColors.primaryOnDark, size: 22),
              ),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong(context)?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.md),
          Row(
            children: [
              Text('$learned/$total thẻ',
                  style: AppText.caption(context)
                      ?.copyWith(color: AppColors.bodyMuted)),
              const Spacer(),
              Text('$percent%',
                  style: AppText.caption(context)?.copyWith(
                      color: AppColors.primaryOnDark,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: Sp.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(R.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ lớp học — store-utility-card với ô màu dẫn + thông tin lớp.
class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.name,
    required this.teacher,
    required this.newItems,
  });

  final String name;
  final String teacher;
  final int newItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(R.md),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.class_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong(context)),
                const SizedBox(height: Sp.xxs),
                Text('GV: $teacher · $newItems bài mới',
                    style: AppText.caption(context)
                        ?.copyWith(color: AppColors.inkMuted48)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.inkMuted48),
        ],
      ),
    );
  }
}
