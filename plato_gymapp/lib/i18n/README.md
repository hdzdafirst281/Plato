# Hệ Thống Đa Ngôn Ngữ (i18n)

Hệ thống đa ngôn ngữ của Plato được quản lý tập trung thông qua **Google Sheets** và sử dụng package `slang` để sinh code tự động.

## 🌟 Quy trình hoạt động (Workflow)

1. **Source of Truth**: File Google Sheets là nguồn dữ liệu duy nhất. Mọi thay đổi về từ ngữ, thêm/bớt key đều phải thực hiện trên Sheet này.
2. **Fetch Dữ Liệu**: Chạy script `fetch_langs.dart` để tự động tải bản dịch mới nhất từ Google Sheets về máy.
3. **Parse & Gen Code**: Script sẽ tự động chuyển đổi định dạng CSV từ Sheet thành các file `.i18n.json` (`strings_en.i18n.json` và `strings_vi.i18n.json`), sau đó kích hoạt `slang` để sinh ra file `strings.g.dart`.

## 🛠 Cách Cập Nhật Ngôn Ngữ Mới
Mỗi khi có thay đổi trên Google Sheets, bạn hãy đợi khoảng **1 đến 2 phút** (vì Google Sheets cần thời gian lưu cache để cập nhật file CSV xuất ra Web). Sau đó, chạy lệnh sau ở thư mục gốc của app (`plato_gymapp`):

```bash
dart scripts/fetch_langs.dart
```

Lệnh này sẽ tải về file ngôn ngữ mới nhất, so sánh với bản cũ để in ra **Báo cáo đồng bộ (Diff)** (các thay đổi Thêm/Xóa/Sửa), và tự động build lại file `strings.g.dart`.

## 📝 Quy ước định dạng trên Google Sheets

File sheet cần có 3 cột chính theo đúng thứ tự:
1. `key`: Mã định danh của chuỗi (vd: `auth.btn_login`)
2. `en`: Nội dung tiếng Anh
3. `vi`: Nội dung tiếng Việt

*(Lưu ý: Các key trên Sheet đã được quy hoạch tự động theo thuật toán **Advanced Sort** - gom nhóm theo từng Module, sau đó bóc tách tiền tố (prefix) để các thành phần liên quan (như title, desc, lbl, btn, msg...) nằm cạnh nhau một cách gọn gàng và logic nhất, giúp bạn dễ dàng tìm kiếm và chỉnh sửa)*
## ⚙️ Cấu Hình Slang (`slang.yaml`)
Hệ thống được cấu hình để đọc các file `.i18n.json` được gen ra từ script:
```yaml
base_locale: en
fallback_strategy: base_locale
input_directory: lib/i18n
input_file_pattern: .i18n.json
output_directory: lib/i18n
output_file_name: strings.g.dart
string_interpolation: braces
key_case: snake
```
*(Không chỉnh sửa trực tiếp vào file `strings_en.i18n.json`, `strings_vi.i18n.json` hay `strings.g.dart` vì chúng sẽ bị ghi đè mỗi khi chạy script).*
