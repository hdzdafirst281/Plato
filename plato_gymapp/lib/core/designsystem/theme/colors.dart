import 'package:flutter/material.dart';

// 1. Màu nền (Background & Surface)
const bgDark = Color.fromARGB(255, 13, 13, 13); 
const bgLight = Color.fromARGB(255, 245, 245, 245);
const surfaceDark = Color(0xFF1E1E1E);
const surfaceLight = Color(0xFFFFFFFF);

// 2. Màu chủ đạo (Primary & Accent)
const primaryBlueDark = Color(0xFF1E88E5);
const primaryBlueLight = Color(0xFF1976D2); 

// 3. Màu Text
const textWhite = Color(0xFFFFFFFF);
const textBlack = Color(0xFF121212);
const textGrayDark = Color(0xFFAAAAAA);
const textGrayLight = Color(0xFF757575);

// ==========================================
// MÀU TRẠNG THÁI (ĐÃ TĂNG BÃO HÒA CHO DARK MODE)
// ==========================================
// 4a. Status - Dark Mode (Bật tone rực rỡ / Neon)
const xpGoldDark = Color(0xFFFFC107);       // Amber 500 (Vàng Gold chuẩn, phát sáng)
const successGreenDark = Color(0xFF4CAF50); // Green 500 (Xanh lá mạnh mẽ)
const warningOrangeDark = Color(0xFFFFA726); // Orange 400 (Cam rực)
const errorRedDark = Color(0xFFEF5350);     // Red 400 (Đỏ cảnh báo nổi bật)
const chartPurpleDark = Color(0xFFAB47BC);  // Purple 400 (Tím đậm đà hơn)

// 4b. Status - Light Mode (Đậm, bão hòa cực cao)
const xpGoldLight = Color(0xFFFF8F00);
const successGreenLight = Color(0xFF2E7D32);
const warningOrangeLight = Color(0xFFEF6C00);
const errorRedLight = Color(0xFFC62828);
const chartPurpleLight = Color(0xFF7B1FA2);

// 4c. Accent - Dark Mode (Tăng cường sắc độ)
const accentTealDark = Color(0xFF26A69A);   // Teal 400 (Sâu và nổi hơn)
const accentPurpleDark = Color(0xFFAB47BC); // Purple 400

// 4d. Accent - Light Mode 
const accentTealLight = Color(0xFF00796B);  
const accentPurpleLight = Color(0xFF7B1FA2); 

// ==========================================
// MÀU HEATMAP (ĐÃ TĂNG BÃO HÒA CHO DARK MODE)
// ==========================================
// 5. Base (Giữ nguyên theo logic masking của bạn)
const heatmapBaseDark = Color(0xFFF0F0F0); 
const heatmapUnusedDark = Color(0xFFB0BEC5);
const heatmapBorderDark = Color(0xFF546E7A);

const heatmapBaseLight = Color(0xFF2C2C2C);
const heatmapUnusedLight = Color(0xFFD6D6D6);
const heatmapBorderLight = Color(0xFFBDBDBD);

// 6a. Heatmap - Dark Mode (Rực rỡ để dễ phân biệt cường độ)
const heatmapLowDark = Color(0xFF66BB6A);     // Nâng tone xanh
const heatmapMedDark = Color(0xFFFFCA28);     // Nâng tone vàng
const heatmapHighDark = Color(0xFFFF7043);    // Nâng tone cam
const heatmapExtremeDark = Color(0xFFEF5350); // Nâng tone đỏ
const heatmapFreqDoneDark = Color(0xFF42A5F5);// Nâng tone xanh dương
const heatmapSelectedDark = Color(0xFFE040FB); // Đã đủ độ "Neon"

// 6b. Heatmap - Light Mode (Bão hòa cao, rực rỡ)
const heatmapLowLight = Color(0xFF388E3C);     
const heatmapMedLight = Color(0xFFF57F17);     
const heatmapHighLight = Color(0xFFE64A19);    
const heatmapExtremeLight = Color(0xFFD32F2F); 
const heatmapFreqDoneLight = Color(0xFF1976D2);
const heatmapSelectedLight = Color(0xFF9C27B0);

// ==========================================
// MÀU ĐỒ HỌA ĐẶC TẢ & HỆ THỐNG RANK (MỚI)
// ==========================================

// 7a. Đồ họa & Rank - Dark Mode (Bật tone rực rỡ / Neon)
const fireHexagonDark = Color(0xFFFF5722); // Màu lửa chuẩn (Deep Orange 500)
const rankBronzeDark = Color(0xFFCF853F);  // Màu Đồng sáng để nổi trên nền đen (Orange 500/Copper)
const rankSilverDark = Color(0xFF90A4AE);  // Màu Bạc sáng (Blue Grey 400)
const rankGoldDark = Color(0xFFFFC107);    // Màu Vàng rực rỡ (Amber 500)
const rankDiamondDark = Color(0xFF00BCD4); // Xanh kim cương Neon (Cyan 500/A200)

// 7b. Đồ họa & Rank - Light Mode (Đậm đà, tương phản cao)
const fireHexagonLight = Color(0xFFD84315); // Màu lửa đậm (Deep Orange 800)
const rankBronzeLight = Color(0xFFA0522D);  // Màu Đồng sẫm (Sienna)
const rankSilverLight = Color(0xFF757575);  // Màu Bạc xám đậm (Grey 600)
const rankGoldLight = Color(0xFFF57F17);    // Màu Vàng cam sậm (Yellow 800)
const rankDiamondLight = Color(0xFF0097A7); // Xanh kim cương đậm (Cyan 700)

// ==========================================
// MÀU WATER TRACKER (ĐA DẠNG HÓA UI)
// ==========================================
// Water - Dark Mode (Gradient sâu thẳm, bão hòa cao mang sắc thái đại dương)
const waterBgStartDark = Color(0xFF153E75); // Deep Navy (Đáy sâu)
const waterBgEndDark = Color(0xFF0A192F);   // Ocean Navy (Mặt nước hắt sáng xanh rực rỡ)
const waterEmptyDropDark = Color(0xFF2A374A); // Mới: Nhạt hơn 1E293B một chút
const waterAccentDark = Color(0xFF42A5F5);  // Blue 400

// Water - Light Mode (Gradient tươi mát, trong trẻo như sương sớm)
const waterBgStartLight = Color(0xFFDDF1FF); // Alice Blue (Sáng, gần như trắng để tạo bóng kính)
const waterBgEndLight = Color(0xFF82C8FF);   // Blue 100 (Đậm hơn hẳn để tạo chiều sâu cho đáy)
const waterEmptyDropLight = Color(0xFFE3F2FD); // Đã chỉnh nhạt lại một chút để nổi bật trên nền Blue 100
const waterAccentLight = Color(0xFF2196F3);  // Blue 500

// ==========================================
// MÀU PODIUM LEADERBOARD (Bục Vinh Quang)
// ==========================================
// Podium - Dark Mode (Tăng bão hòa, rực rỡ và có độ bóng Neon)
const podiumGoldStartDark = Color(0xFFFFCA28);   // Amber 400 (Vàng chói)
const podiumGoldEndDark = Color(0xFFFF8F00);     // Amber 800 (Tạo khối sâu mạnh mẽ)
const podiumSilverStartDark = Color(0xFFE3F2FD); // Blue 50 (Sáng chói, ánh thép xanh)
const podiumSilverEndDark = Color(0xFF90A4AE);   // Blue Grey 400 (Bạc thép)
const podiumBronzeStartDark = Color(0xFFD97D3A); // Đã giảm ánh Vàng, tăng sắc Đỏ/Nâu
const podiumBronzeEndDark = Color(0xFF9E481E);   // Đáy bục màu Đồng sẫm tạo khối sâu

// Podium - Light Mode (Đậm đà, tạo khối rõ ràng)
const podiumGoldStartLight = Color(0xFFFFC107); 
const podiumGoldEndLight = Color(0xFFFF8F00);
const podiumSilverStartLight = Color(0xFFB0BEC5);
const podiumSilverEndLight = Color(0xFF607D8B);
const podiumBronzeStartLight = Color(0xFFCF853F);
const podiumBronzeEndLight = Color(0xFF8D5524);

// ==========================================
// MÀU WEEKLY CHEST BANNER (Rương Thưởng Tuần)
// ==========================================
// Chest - Dark Mode (Tím sáng rực)
const chestBannerStartDark = Color(0xFFE040FB);  // Purple A200 (Tím Neon chói lóa)
const chestBannerEndDark = Color(0xFF7C4DFF);    // Deep Purple A200 (Tím xanh vũ trụ)

// Chest - Light Mode (Tím sâu thẳm, huyền bí)
const chestBannerStartLight = Color(0xFF512DA8);
const chestBannerEndLight = Color(0xFF7B1FA2);

// ==========================================
// MÀU COMPACT STAT CARD GRADIENT (MỚI)
// ==========================================
// Dark Theme (Giữ nguyên độ rực rỡ, phát sáng trên nền tối)
const streakGradientStartDark = Color(0xFFF05756); // Coral Red
const streakGradientEndDark = Color(0xFFF89D2A);   // Golden Orange

// Light Theme (Sắc độ sâu hơn một chút để nổi bật và dễ nhìn trên nền sáng)
const streakGradientStartLight = Color(0xFFF05756); 
const streakGradientEndLight = Color(0xFFF89D2A);

// Rest Card (Nghỉ ngơi/Phục hồi - Gradient Xanh Dương Dịu Mát)
const restGradientStartDark = Color(0xFF1565C0); // Light Blue 300
const restGradientEndDark = Color(0xFF4FC3F7);   // Blue 800
const restGradientStartLight = Color(0xFF1976D2); // Light Blue 200
const restGradientEndLight = Color(0xFF81D4FA);   // Blue 700

// ==========================================
// MÀU XP LEVEL PROGRESS BAR (MỚI)
// ==========================================
// XP Bar - Dark Mode (Vàng sáng chói chuyển sang Cam rực lửa)
const xpGradientStartDark = Color(0xFFFFD54F); // Amber 300
const xpGradientEndDark = Color(0xFFFF7043);   // Deep Orange 400

// XP Bar - Light Mode (Vàng sậm chuyển sang Cam đậm)
const xpGradientStartLight = Color(0xFFFFC107); // Amber 500
const xpGradientEndLight = Color(0xFFF4511E);   // Deep Orange 600

// ==========================================
// MÀU NUTRITION DASHBOARD (MỚI)
// ==========================================
// Nutrition - Dark Mode (Đêm tĩnh lặng - Midnight Slate)
// Nền xám xanh sâu thẳm. Các màu nổi (đỏ, cam, xanh, trắng) sẽ phát sáng rực rỡ.
// Không dùng đen tuyệt đối (0xFF000000) nên nếu bạn có viền hoặc khối màu đen, nó vẫn sẽ tách biệt được.
const nutritionBgStartDark = Color(0xFF334155); // Slate 700 (Xám xanh sáng nhẹ tạo góc gradient)
const nutritionBgEndDark = Color(0xFF0F172A);   // Slate 900 (Đen xám sâu thẳm làm nền chính)
const nutritionEmptyDark = Color(0xFF1E293B);

// Nutrition - Light Mode (Sữa yến mạch & Đá xám - Oat Milk & Silver)
// Tone xám nhạt trung tính. Nó đủ "đục" để màu Trắng nổi lên được dưới dạng Card/Box,
// đủ sáng để màu Đen sắc nét, và hoàn toàn không "đá" các màu sắc biểu đồ (xanh, đỏ, cam).
const nutritionBgStartLight = Color(0xFFF1F5F9); // Slate 100 (Trắng xám mờ, dịu mắt)
const nutritionBgEndLight = Color(0xFFB2C2D4); // Slate 350: Rõ nét sắc xám xanh, đủ độ sâu để Card màu trắng (0xFFFFFFFF) tách lớp hoàn toàn
const nutritionEmptyLight = Color(0xFFF3F6F9); 