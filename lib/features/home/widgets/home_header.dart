import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// HEADER trang chủ (SCREENS §3) — lời chào + chuông thông báo + avatar.
///
/// Đây là "đầu trang" dùng chung cho HomeScreen. Đặt ở đầu vùng cuộn nên nó
/// cuộn theo nội dung (không dính cứng như AppBar) — đúng cảm giác Apple large-title.
///
/// - [name]        : tên hiển thị sau "Chào,".
/// - [subtitle]    : dòng phụ (mặc định "Hôm nay học gì nào?").
/// - [hasUnread]   : hiện chấm đỏ trên chuông.
/// - [onBell]/[onAvatar] : callback khi bấm chuông / avatar.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.name = 'bạn',
    this.subtitle = 'Hôm nay học gì nào?',
    this.hasUnread = false,
    this.onBell,
    this.onAvatar,
  });

  final String name;
  final String subtitle;
  final bool hasUnread;
  final VoidCallback? onBell;
  final VoidCallback? onAvatar;

  String get _initial {
    final t = name.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Chào, $name 👋',
                style: AppText.displayMd(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Sp.xs),
            _BellButton(hasUnread: hasUnread, onTap: onBell),
            const SizedBox(width: Sp.xs),
            _Avatar(initial: _initial, onTap: onAvatar),
          ],
        ),
        const SizedBox(height: Sp.xxs),
        Text(
          subtitle,
          style: AppText.body(context)?.copyWith(color: AppColors.inkMuted80),
        ),
      ],
    );
  }
}

/// Nút chuông thông báo với chấm đỏ tuỳ chọn.
class _BellButton extends StatelessWidget {
  const _BellButton({required this.hasUnread, this.onTap});

  final bool hasUnread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: 'Thông báo',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded,
              size: 26, color: AppColors.ink),
          if (hasUnread)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.canvas, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Avatar tròn — hiện chữ cái đầu của tên (placeholder, sau thay bằng ảnh).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, this.onTap});

  final String initial;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.parchment,
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
