#!/bin/bash

# Danh sách các thư mục cần xử lý
DIRECTORIES=("assets/gifs" "assets/images")

echo "Bắt đầu convert ảnh (GIF, PNG, JPG) sang WebP (Chế độ An Toàn)..."

# Hàm xử lý convert để tái sử dụng
convert_to_webp() {
    local file="$1"
    # Lấy đường dẫn file không bao gồm phần mở rộng (đuôi file)
    local filename="${file%.*}"
    local output="${filename}.webp"

    echo "Đang xử lý: $file"
    
    # Chạy ffmpeg, kiểm tra trạng thái exit code bằng if-else cho dễ đọc và an toàn
    if ffmpeg -v error -i "$file" -vcodec libwebp -lossless 0 -q:v 80 -loop 0 -an -preset default -y "$output"; then
        rm "$file"
        echo "-> Thành công: Đã xóa file gốc."
    else
        echo "-> LỖI: Không thể nén $file, giữ nguyên file gốc."
    fi
}

# nullglob: Tránh lỗi vòng lặp trả về chuỗi "*.png" nếu không tìm thấy file nào
# nocaseglob: Bắt được cả các file viết hoa đuôi như .PNG, .GIF, .JPG
shopt -s nullglob nocaseglob

# Lặp qua từng thư mục trong mảng
for dir in "${DIRECTORIES[@]}"; do
    # Kiểm tra xem thư mục có tồn tại không
    if [ ! -d "$dir" ]; then
        echo "Cảnh báo: Thư mục '$dir' không tồn tại, bỏ qua."
        continue
    fi

    echo "----------------------------------------"
    echo "Đang quét thư mục: $dir"
    
    # Lặp qua các định dạng cần convert (đã bổ sung thêm jpg/jpeg cho thư mục images)
    for file in "$dir"/*.{gif,png,jpg,jpeg}; do
        # Đảm bảo file tồn tại và là regular file (không phải directory)
        if [ -f "$file" ]; then
            convert_to_webp "$file"
        fi
    done
done

# Tắt cài đặt shopt trả về mặc định
shopt -u nullglob nocaseglob

echo "----------------------------------------"
echo "Hoàn tất toàn bộ!"