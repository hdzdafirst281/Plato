import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:responsive_framework/responsive_framework.dart'; // [ADD] Import Responsive

class GymTourTarget extends StatelessWidget {
  final GlobalKey tourKey;
  final String title;
  final String description;
  final Widget child;
  
  // Customization
  final double borderRadius;
  final EdgeInsets targetPadding;
  final ShapeBorder? customShapeBorder;

  final bool? disposeOnTap;
  final VoidCallback? onTargetClick;
  
  // [UI/UX FIX]: Bổ sung tooltipPosition để chủ động ép hướng bong bóng
  final TooltipPosition? tooltipPosition; 
  final bool isActive;

  const GymTourTarget({
    super.key,
    required this.tourKey,
    required this.title,
    required this.description,
    required this.child,
    this.borderRadius = 8.0, 
    this.targetPadding = const EdgeInsets.all(4.0), 
    this.customShapeBorder,
    this.disposeOnTap, 
    this.onTargetClick, 
    this.tooltipPosition, // Nhận giá trị từ bên ngoài
    this.isActive = true, // Mặc định là true để tương thích ngược
  });

  EdgeInsets _resolveTargetPadding(BuildContext context) {
    final basePadding = targetPadding.resolve(Directionality.of(context));

    if (basePadding == EdgeInsets.zero) {
      return basePadding;
    }

    final isCompact = ResponsiveBreakpoints.of(context).smallerThan(MOBILE);
    final isVerySmall = MediaQuery.of(context).size.width < 360;
    final scale = isVerySmall ? 0.75 : isCompact ? 0.9 : 1.0;

    return EdgeInsets.only(
      left: (basePadding.left > 0 ? basePadding.left : 2.0) * scale,
      right: (basePadding.right > 0 ? basePadding.right : 2.0) * scale,
      top: (basePadding.top > 0 ? basePadding.top : 2.0) * scale,
      bottom: (basePadding.bottom > 0 ? basePadding.bottom : 2.0) * scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // [UI/UX FIX]: Bóp nhẹ Font Size trên màn hình nhỏ để bong bóng không phình quá to
    final titleSize = ResponsiveValue<double>(
      context, 
      defaultValue: 16, 
      conditionalValues: [Condition.smallerThan(name: MOBILE, value: 14)]
    ).value;
    
    final descSize = ResponsiveValue<double>(
      context, 
      defaultValue: 14, 
      conditionalValues: [Condition.smallerThan(name: MOBILE, value: 12)]
    ).value;

    if (!isActive) {
      return child;
    }

    return Showcase(
      key: tourKey,
      title: title,
      description: description,
      disposeOnTap: disposeOnTap, 
      onTargetClick: onTargetClick,
      
      // [CRITICAL FIX]: Gắn tooltipPosition. Nếu null, Showcase tự động tính.
      // Khi khai báo ở màn hình, nếu sợ dính nút đáy, hãy truyền: tooltipPosition: TooltipPosition.top
      tooltipPosition: tooltipPosition, 
      
      // 1. Tùy chỉnh Shape (Giữ highlight đúng hình dáng button/widget)
      targetShapeBorder: customShapeBorder ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      targetPadding: _resolveTargetPadding(context),
      
      // 2. Tùy chỉnh bong bóng hội thoại (Tooltip)
      tooltipBackgroundColor: theme.colorScheme.primary, 
      textColor: theme.colorScheme.onPrimary, 
      titleAlignment: Alignment.center,
      
      // 3. Text Styles
      titleTextStyle: TextStyle(
        fontSize: titleSize, // Đã bọc Responsive
        fontWeight: FontWeight.bold, 
        color: theme.colorScheme.onPrimary
      ),
      descTextStyle: TextStyle(
        fontSize: descSize, // Đã bọc Responsive
        height: 1.2, // [UI/UX FIX]: Nén chiều cao dòng lại để bong bóng lùn hơn
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.9)
      ),
      
      // 4. Animation config
      movingAnimationDuration: const Duration(milliseconds: 300),
      scaleAnimationCurve: Curves.easeInOut,
      
      child: child,
    );
  }
}