# Quy trình chuẩn cho AI Agent khi thay đổi Plato

## Mục đích và phạm vi

File này là cổng quyết định bắt buộc cho mọi AI agent khi phân tích, sửa lỗi, thay đổi UI, phát triển tính năng, cập nhật dữ liệu hoặc chỉnh sửa tài liệu trong repository Plato.

Agent phải đọc file này trước khi thay đổi repository. Mục tiêu là:

- không hỏi người dùng về những quyết định kỹ thuật có thể suy ra an toàn từ code;
- chỉ hỏi khi câu trả lời làm thay đổi hành vi nghiệp vụ, dữ liệu, bảo mật, phạm vi Use Case hoặc khả năng tương thích;
- giữ code, Use Case và DOCX generated đồng bộ;
- không ghi đè hoặc làm mất thay đổi đang có của người dùng.

Chỉ dẫn trực tiếp mới nhất của người dùng luôn có ưu tiên cao hơn file này.

## Nguồn chuẩn

- Code ứng dụng: `plato_gymapp/`.
- Nội dung chi tiết UC01-UC31: `plato_docs/usecases/UCxx.md`.
- Mapping code, localization và quan hệ UC: `plato_docs/usecase-index.yaml`.
- Metadata trình bày, nhóm và thuật ngữ: `plato_docs/usecase-document.yaml`.
- Template Word: `plato_docs/templates/usecase-template.docx`.
- DOCX đầu ra: `plato_docs/generated/plato_usecases.docx`.
- Bản Word lịch sử: `plato_docs/archive/`; không dùng làm nguồn và không sửa.

Không sửa trực tiếp DOCX generated. Mọi thay đổi nội dung phải đi qua Markdown/YAML rồi chạy generator.

## Bước 1: Kiểm tra trạng thái trước khi làm

Trước khi sửa, agent phải:

1. Đọc yêu cầu và các file code/test/UC liên quan.
2. Chạy `git status --short` và phân biệt thay đổi của người dùng với thay đổi của agent.
3. Không hoàn tác, format hàng loạt, di chuyển hoặc ghi đè thay đổi không thuộc yêu cầu.
4. Xác định phạm vi nhỏ nhất đủ giải quyết yêu cầu, bao gồm caller, test, localization, mapping và tài liệu có thể bị ảnh hưởng.
5. Nếu chỉ được yêu cầu chẩn đoán hoặc review, không tự triển khai fix nếu người dùng chưa yêu cầu.

## Bước 2: Phân loại thay đổi

Agent phải phân loại trước khi quyết định có hỏi người dùng hay không.

### Loại A — không thay đổi nghiệp vụ, không cần hỏi

Agent tự xử lý nếu yêu cầu đã rõ:

- debug hoặc sửa bug để code trở lại đúng hành vi đã được UC/test mô tả;
- thay đổi UI thuần túy: màu, spacing, typography, animation, responsive layout hoặc indicator;
- refactor không đổi input, output, side effect hoặc luồng người dùng;
- tối ưu hiệu năng không đổi kết quả hoặc tính nhất quán dữ liệu;
- bổ sung test cho hành vi hiện có;
- sửa typo, comment, log hoặc tài liệu kỹ thuật không đổi nội dung nghiệp vụ;
- cập nhật dependency tương thích, nếu không có migration hoặc thay đổi public API.

Nếu impact scanner báo UC cho thay đổi Loại A, agent không sửa nội dung UC chỉ để làm yên công cụ. Agent ghi `reviewed-no-change` cùng lý do trong phần bàn giao hoặc Pull Request.

### Loại B — thay đổi nghiệp vụ nhưng quyết định đã rõ, không cần hỏi lại

Agent có thể triển khai và cập nhật UC hiện hữu khi người dùng đã mô tả rõ kết quả mong muốn và thay đổi chỉ mở rộng một mục tiêu nghiệp vụ đã có, ví dụ:

- thêm một bước hoặc một nhánh lỗi vào luồng hiện hữu;
- thay đổi validation, business rule hoặc phép tính đã được người dùng chỉ định cụ thể;
- thêm trường dữ liệu không phá dữ liệu cũ và cách dùng đã rõ;
- thêm localization hoặc file code cho UC đã xác định được.

Agent phải nêu giả định trong bàn giao nếu có, nhưng không hỏi chỉ để xác nhận lại nội dung người dùng vừa yêu cầu rõ ràng.

### Loại C — có quyết định sản phẩm hoặc rủi ro, phải hỏi trước

Agent phải dừng trước phần triển khai phụ thuộc vào quyết định và hỏi người dùng khi tồn tại từ hai phương án hợp lý trở lên làm thay đổi một trong các yếu tố sau:

- mục tiêu, actor, trigger, kết quả hoặc luồng chính của người dùng;
- tạo UC mới hay mở rộng UC hiện hữu;
- công thức, giới hạn, giá trị mặc định hoặc business rule chưa được xác định;
- schema, migration, xóa dữ liệu, ghi đè dữ liệu hoặc khả năng tương thích ngược;
- nguồn dữ liệu ưu tiên khi local và cloud xung đột;
- đăng nhập, phân quyền, quyền hệ điều hành, bảo mật hoặc quyền riêng tư;
- notification, background service hoặc hành vi khi ứng dụng không hoạt động;
- API/backend contract, thanh toán hoặc tích hợp bên thứ ba;
- hành vi offline, retry, timeout, duplicate request hoặc failure recovery;
- thay đổi Điều khoản sử dụng, EULA hoặc nội dung pháp lý;
- hành động phá hủy, phát hành công khai hoặc thay đổi trạng thái hệ thống bên ngoài.

Không hỏi về naming, cấu trúc test, vị trí helper, style code hoặc chi tiết implementation nếu có thể suy ra từ repository.

## Cách đặt câu hỏi quyết định

Agent phải gom câu hỏi thành một lượt ngắn, tối đa ba câu nếu có thể. Mỗi câu phải:

1. Nêu quyết định cần chốt.
2. Đưa ra phương án đề xuất đầu tiên.
3. Nêu ảnh hưởng của từng lựa chọn tới code, dữ liệu hoặc Use Case.

Chỉ hỏi những câu mà câu trả lời thực sự làm thay đổi implementation. Ví dụ:

- “Tính năng chia sẻ kết quả là một bước của UC17 hay một mục tiêu độc lập cần UC mới?”
- “Khi local và cloud cùng thay đổi, nguồn nào thắng hay cần hỏi người dùng chọn?”
- “Dữ liệu cũ phải migration hay có thể đặt giá trị mặc định?”

Trong lúc chờ quyết định, agent vẫn có thể thực hiện kiểm tra read-only và chuẩn bị các phần không phụ thuộc vào câu trả lời.

## Bước 3: Xác định Use Case bị ảnh hưởng

Impact scanner chỉ là bộ cảnh báo dựa trên Git diff, `code_paths` và localization key. Nó không hiểu ngữ nghĩa Dart và không tự quyết định có cần UC mới.

Từ root repository, dùng Python trong `.venv`:

```powershell
.\.venv\Scripts\python.exe tools\check_usecase_impact.py --staged --fail-on-unclassified
```

Với branch đã có commit:

```powershell
.\.venv\Scripts\python.exe tools\check_usecase_impact.py --base main --fail-on-unclassified
```

Với file chưa stage và đã biết phạm vi:

```powershell
.\.venv\Scripts\python.exe tools\check_usecase_impact.py --files <path-1> <path-2> --fail-on-unclassified
```

`--files` không tính diff localization key; dùng `--staged` hoặc `--base` khi localization thay đổi.

Khi có `Unclassified scoped files`, agent phải xác định:

- file thuộc UC hiện hữu: bổ sung `code_paths`;
- file ảnh hưởng nhiều UC: mapping vào tất cả UC thực sự liên quan;
- file chỉ là implementation detail: mapping vào UC mà nó phục vụ;
- hành vi là mục tiêu độc lập: chuyển sang cổng quyết định UC mới.

## Tiêu chí UC hiện hữu hay UC mới

Ưu tiên cập nhật UC hiện hữu khi thay đổi vẫn phục vụ cùng mục tiêu người dùng và có thể mô tả hợp lý như một bước, subflow hoặc alternate flow.

Chỉ đề xuất UC mới khi hành vi có phần lớn các đặc điểm sau:

- mục tiêu người dùng độc lập;
- entry point hoặc trigger riêng;
- luồng chính và kết quả riêng;
- tiền điều kiện hoặc hậu điều kiện riêng;
- business rule riêng;
- có thể kiểm thử hoặc sử dụng độc lập.

Generator hiện gắn với 31 UC và 31 bảng trong template. Không tự thêm UC32 nếu chưa có xác nhận của người dùng. Khi được duyệt, phạm vi phải gồm Markdown, index, document metadata, template, generator, validator, test và DOCX generated.

## Bước 4: Triển khai thay đổi nhỏ nhất nhưng đầy đủ

Agent phải:

- tuân theo kiến trúc và pattern sẵn có;
- sửa nguyên nhân gốc thay vì vá nhiều caller;
- không thêm dependency, abstraction hoặc config nếu chưa cần;
- giữ error handling, validation, accessibility và localization;
- thêm hoặc cập nhật test cho logic không tầm thường;
- không tự sửa lỗi không liên quan chỉ vì nhìn thấy trong lúc làm;
- format đúng các file đã sửa, không format hàng loạt repository.

Với bug fix, agent phải tìm caller và test liên quan trước khi sửa. Nếu UC đang mô tả đúng hành vi mong muốn thì không đổi UC; nếu UC và code mâu thuẫn mà yêu cầu không nói nguồn nào đúng, phải hỏi.

## Bước 5: Đồng bộ tài liệu

### Không đổi nghiệp vụ

- Không sửa Markdown UC hoặc DOCX generated.
- Đảm bảo file mới vẫn được mapping nếu thuộc `plato_gymapp/lib/`.
- Ghi `reviewed-no-change: <UC> — <lý do>`.
- Chạy `build_usecase_doc.py --check` để chắc output hiện tại không stale.

### Thay đổi UC hiện hữu

Tùy phạm vi, cập nhật:

1. `plato_docs/usecases/UCxx.md` cho mục tiêu, actor, điều kiện, luồng, ngoại lệ, hậu điều kiện, quy tắc và thuật ngữ.
2. `plato_docs/usecase-index.yaml` cho title, source, feature, `code_paths`, localization key và `related_usecases`.
3. `plato_docs/usecase-document.yaml` cho nhóm, summary, importance, type, actor, relationship và glossary.

Giữ đồng bộ quan hệ UC giữa Markdown, index và document metadata.

Sau khi nguồn thay đổi, đóng DOCX đang mở rồi chạy:

```powershell
.\.venv\Scripts\python.exe tools\validate_usecases.py --strict
.\.venv\Scripts\python.exe tools\build_usecase_doc.py
.\.venv\Scripts\python.exe tools\build_usecase_doc.py --check
.\.venv\Scripts\python.exe -m unittest discover --start-directory tools/tests --pattern "test_*.py"
```

## Bước 6: Kiểm chứng code

Agent chọn mức kiểm chứng tương ứng rủi ro:

- luôn chạy test gần nhất với phần đã sửa;
- chạy formatter/analyzer cho phạm vi phù hợp;
- chạy test toàn bộ khi thay đổi shared logic, dữ liệu, navigation, authentication, synchronization hoặc trước khi bàn giao một feature lớn;
- nếu không thể chạy một kiểm tra, phải nói rõ kiểm tra nào bị bỏ qua và rủi ro còn lại.

Các lệnh Flutter/Dart phải chạy trong `plato_gymapp/`. Không chạy `pub get`, migration, code generation hoặc lệnh có thể thay đổi nhiều file nếu yêu cầu không cần đến chúng.

## Bước 7: Kiểm tra trước khi commit hoặc Pull Request

Sau khi stage đúng phạm vi, chạy lại:

```powershell
.\.venv\Scripts\python.exe tools\check_usecase_impact.py --staged --fail-on-unclassified
.\.venv\Scripts\python.exe tools\validate_usecases.py --strict
.\.venv\Scripts\python.exe tools\build_usecase_doc.py --check
git diff --check
```

Agent không tự commit, push, merge, phát hành hoặc bật CD artifact nếu người dùng chưa yêu cầu.

## Bước 8: Bàn giao

Bàn giao phải ngắn gọn nhưng có đủ:

- kết quả đã hoàn thành;
- phân loại thay đổi A, B hoặc C;
- UC bị ảnh hưởng và trạng thái `updated` hoặc `reviewed-no-change`;
- file chính đã sửa;
- test, validator và generator check đã chạy;
- kiểm tra bị bỏ qua và rủi ro còn lại;
- quyết định hoặc thao tác còn cần người dùng thực hiện.

Mẫu tối thiểu:

```text
Kết quả: ...
Phân loại: A/B/C
Use Case: UCxx — updated/reviewed-no-change
Kiểm chứng: ...
Còn lại/rủi ro: ...
```

## Quy trình tóm tắt

```text
Đọc yêu cầu và trạng thái Git
→ phân loại A/B/C
→ chỉ hỏi nếu có quyết định Loại C
→ xác định UC bằng impact scanner và review ngữ nghĩa
→ triển khai code + test
→ cập nhật Markdown/YAML nếu nghiệp vụ đổi
→ validate + generate/check DOCX
→ staged impact check
→ bàn giao rõ quyết định, kiểm chứng và rủi ro
```
