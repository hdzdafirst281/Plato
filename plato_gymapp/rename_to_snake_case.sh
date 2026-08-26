#!/bin/bash

ASSET_DIR="assets/gifs"

echo "Bắt đầu kiểm tra và chuẩn hóa tên file thành snake_case..."

# Dùng lệnh find để xử lý an toàn các file có chứa khoảng trắng trong tên
find "$ASSET_DIR" -maxdepth 1 -type f \( -iname "*.gif" -o -iname "*.png" \) | while read -r file; do
    dir=$(dirname "$file")
    base=$(basename "$file")
    
    # 1. Chuyển toàn bộ thành chữ thường (lowercase)
    # 2. Đổi khoảng trắng ' ' và gạch ngang '-' thành gạch dưới '_'
    # 3. Xóa các ký tự đặc biệt nếu có (chỉ giữ lại chữ, số, gạch dưới và dấu chấm)
    new_base=$(echo "$base" | tr '[:upper:]' '[:lower:]' | sed -E 's/[ -]+/_/g' | sed -E 's/[^a-z0-9_.]//g')
    
    # Nếu tên mới khác tên cũ, tiến hành đổi tên
    if [ "$base" != "$new_base" ]; then
        mv -v "$file" "$dir/$new_base"
    fi
done

echo "Hoàn tất chuẩn hóa tên file!"