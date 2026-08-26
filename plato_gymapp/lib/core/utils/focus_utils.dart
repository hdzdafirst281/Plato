import 'package:flutter/material.dart';

/// Tiện ích tự động xóa Focus (ẩn con trỏ, ẩn bàn phím) 
/// khi người dùng chạm vào bất kỳ vùng trống nào trên màn hình.
class GlobalFocusUtils extends StatelessWidget {
  final Widget child;

  const GlobalFocusUtils({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // HitTestBehavior.translucent giúp nhận diện cú chạm xuyên qua cả các vùng trống không có màu nền
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // Lấy focus hiện tại và hủy nó đi
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: child,
    );
  }
}