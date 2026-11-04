# Kế hoạch phát triển Recovery Model

## 1. Mục đích

Tài liệu này lưu lộ trình tách, kiểm chứng và cải thiện mô hình Recovery của Plato. Đây là tài liệu nghiên cứu và triển khai trong tương lai, không thay thế mô tả nghiệp vụ hiện hành trong `UC18`.

Mục tiêu dài hạn là dùng dữ liệu thật, có sự đồng ý của người dùng Plato, để hiệu chỉnh và đánh giá mô hình. Dataset công khai chỉ được dùng để xây pipeline, thử adapter và kiểm tra phương pháp trong giai đoạn chưa có đủ dữ liệu Plato; không được xem là ground truth cuối cùng cho Recovery theo nhóm cơ.

Ngày rà soát gần nhất: 2026-11-03.

## 2. Nguyên tắc kiến trúc

Mô hình được tách thành Python package độc lập tại root repository:

```text
recovery_model/
├── README.md
├── pyproject.toml
├── configs/
│   └── plato_baseline_v1.json
├── src/
│   └── plato_recovery/
│       ├── __init__.py
│       ├── schema.py
│       ├── baseline.py
│       ├── features.py
│       ├── prediction.py
│       ├── evaluation.py
│       ├── cli.py
│       └── datasets/
│           ├── plato.py
│           ├── pmdata.py
│           ├── soccermon.py
│           ├── fitrec.py
│           └── persist.py
├── tests/
│   ├── fixtures/
│   │   └── dart_golden_cases.json
│   ├── test_parity.py
│   └── test_evaluation.py
├── data/
│   └── README.md
└── outputs/
```

Python là môi trường nghiên cứu, huấn luyện và đánh giá. App Flutter không chạy Python trực tiếp. Khi một candidate model được chấp nhận, Python xuất cấu hình/model có version để logic Dart sử dụng hoặc được port sang Dart kèm parity test.

Không commit dataset thô, dữ liệu người dùng hay kết quả có thông tin định danh vào Git.

## 3. Baseline phải giữ đúng hành vi app hiện tại

`baseline.py` phải port nguyên hành vi từ các nguồn Dart sau:

- `plato_gymapp/lib/features/workout/domain/recovery_load_calculator.dart`
- `plato_gymapp/lib/features/workout/domain/muscle_recovery_calculator.dart`
- `plato_gymapp/lib/features/workout/domain/muscle_exposure_calculator.dart`
- `plato_gymapp/lib/features/workout/domain/major_muscle_recovery_projection.dart`
- `plato_gymapp/lib/features/workout/domain/recovery_scale.dart`

Baseline phải giữ nguyên các quy tắc hiện hành, kể cả các hệ số chưa được hiệu chỉnh bằng dữ liệu:

- volume theo loại bài;
- EMA `75% cũ + 25% mới`;
- Relative Load tối đa `1.5`;
- Objective Intensity trong `0.75–1.25`;
- Adjusted Relative Load tối đa `1.75`;
- hệ số cơ chính/cơ phụ `1 : 1/3`;
- RPE dự phòng `7` chỉ trong phép tính; dữ liệu gốc tiếp tục là `null` khi người dùng chưa đánh giá;
- fatigue tối đa `150`;
- exponential decay và lambda theo nhóm cơ;
- thang hiển thị Recovery `40/80/100`.

Mục tiêu của baseline không phải chứng minh công thức đúng. Baseline là đối chứng để xác định candidate model có thực sự tốt hơn app hiện tại hay không.

Điều kiện hoàn thành parity:

- Cùng input, Dart và Python trả cùng trạng thái, phần trăm và thời điểm vượt ngưỡng.
- Kết quả phần trăm hiển thị giống tuyệt đối; số thực trung gian dùng tolerance đã định trước.
- Có fixture cho strength, bodyweight, reps-only, cardio, nhiều buổi gần nhau, thiếu RPE và thiếu `endTime`.

## 4. Cân nặng người dùng trong công thức hiện tại

### 4.1 Cân nặng được dùng ở đâu

Code hiện tại chỉ dùng `userBodyWeight` trong trường hợp:

```text
exercise.type == WEIGHT_REPS
và set.weight <= 0
```

Khi đó:

```text
effectiveWeight = userBodyWeight nếu có, nếu không là 1
setVolume = effectiveWeight × reps
```

Giá trị này đi tiếp vào:

1. `exerciseVolume`, từ đó ảnh hưởng capacity EMA và Relative Load của bài.
2. Trọng số khi tính RPE trung bình của các set trong cùng bài.
3. Tải phân bổ sang cơ chính và cơ phụ, rồi đi vào fatigue và Recovery.

Cân nặng không được dùng cho `REPS_ONLY`, `TIME_ONLY`, `CARDIO_DISTANCE` hoặc `CARDIO_STEPS`.

### 4.2 Tác động thực tế bị hạn chế bởi cá nhân hóa

Với một bài luôn có `weight = 0`, cân nặng là hệ số nhân chung cho volume. Vì capacity của chính bài đó cũng được học bằng EMA từ cùng volume, hệ số cân nặng phần lớn bị triệt tiêu trong `load / capacity` khi cân nặng không đổi.

Cân nặng có thể tạo khác biệt rõ hơn khi:

- cùng một bài có cả set `weight = 0` và set có tạ nhập rõ ràng;
- cân nặng thay đổi nhưng có snapshot theo thời điểm buổi tập;
- volume được dùng ở phép tính khác không chuẩn hóa theo capacity;
- sau này model học một hệ số bodyweight riêng từ dữ liệu.

Hiện app chỉ có cân nặng hồ sơ hiện tại. Nếu truyền giá trị này vào toàn bộ lịch sử, cân nặng mới sẽ được áp ngược cho các buổi cũ. Đây không phải lịch sử cân nặng theo thời điểm.

### 4.3 Không nên nối cân nặng vào Recovery một cách máy móc

`weight = 0` có thể mang nhiều nghĩa: bài bodyweight, người dùng quên nhập tạ hoặc bài không cần tạ. Ngoài ra, push-up, pull-up, dip và các bài bodyweight khác không sử dụng 100% khối lượng cơ thể theo cùng một tỷ lệ.

Hướng đúng cho model tương lai là mô tả cách tạo tải của từng bài, ví dụ:

```text
load_source: external_weight | bodyweight_fraction | reps_only
bodyweight_fraction: hệ số riêng của bài, cần có nguồn hoặc được hiệu chỉnh
```

Không tạo các hệ số bodyweight tùy ý trước khi có bằng chứng. Ở giai đoạn parity, Python chỉ sao chép chính xác hành vi hiện tại.

## 5. RPE trong local và Supabase

### 5.1 Hai loại RPE đã được phân biệt theo cấu trúc

RPE của toàn buổi nằm ở cột:

```text
public.workout_history.rpe
```

RPE từng set nằm trong JSONB:

```text
public.workout_history.payload
  .exercises[].sets[].rpe
```

Model Dart tương ứng:

```text
WorkoutSession.rpe        -> RPE toàn buổi
ExerciseSet.rpe           -> RPE từng set
```

Khi chế độ RPE từng set được bật, app chủ động lưu `WorkoutSession.rpe = null` và lưu `payload.rpe_per_set_enabled = true`. Do đó có thể phân biệt:

- `workout_history.rpe` có giá trị: session RPE;
- `payload...sets[].rpe` có giá trị: set RPE;
- `rpe_per_set_enabled = true`: chế độ RPE từng set, kể cả khi mọi set đều chưa đánh giá;
- dữ liệu cũ chưa có cờ nhưng có set RPE: suy ra là chế độ RPE từng set;
- session RPE `null`, không có set RPE và không có cờ: dữ liệu cũ không đủ thông tin để biết người dùng chọn chế độ nào;
- cả hai cùng có giá trị: dữ liệu cũ, dữ liệu nhập từ nguồn khác hoặc trạng thái cần audit; Recovery hiện ưu tiên set RPE cho set đó.

Mọi phép tính cần RPE dùng giá trị dự phòng 7 khi không có Session RPE hoặc Set RPE hợp lệ. Giá trị dự phòng không được ghi ngược vào lịch sử hay dataset; `null` tiếp tục biểu diễn trung thực việc người dùng chưa đánh giá.

Không cần thêm cột database chỉ để phân biệt hai loại RPE. Python adapter nên đọc cờ trong JSONB và flatten JSONB sang một bảng set-level riêng khi chuẩn bị dataset.

### 5.2 Tình trạng dữ liệu cloud tại lần rà soát

Kiểm tra read-only ngày 2026-11-03 cho thấy:

```text
Tổng workout_history được truy vấn: 333
Có session RPE:                 315
Có ít nhất một set RPE:           1
Có cả hai loại RPE:                0
Có cờ rpe_per_set_enabled:         0
```

Schema và code đồng bộ đã bảo toàn trường `sets[].rpe` trong mẫu thực tế. Cờ chế độ mới chỉ xuất hiện trên các buổi được lưu sau khi phiên bản hỗ trợ cờ được phát hành; trước khi dùng set RPE để train, phải tiếp tục theo dõi độ phủ và kiểm tra end-to-end từ app lên cloud rồi pull về local.

### 5.3 Dạng bảng dùng cho Python

Python adapter nên tạo hai bảng logic từ một bản ghi `workout_history`:

```text
sessions
  user_id, session_id, start_time, end_time, duration, session_rpe, ...

sets
  user_id, session_id, exercise_id, set_id, weight, reps, set_rpe, ...
```

Việc flatten thực hiện trong pipeline nghiên cứu; chưa cần thay schema production. Nếu sau này tạo bảng analytics mới trên Supabase, phải dùng RLS, ownership policy và quyền Data API rõ ràng.

## 6. Schema dữ liệu nghiên cứu

### 6.1 Input tối thiểu

```text
user_id_pseudonymous
session_id
session_start
session_end
exercise_id
exercise_type
primary_muscle
secondary_muscles
set_id
set_type
completed
weight_kg
reps
duration_seconds
distance_km
steps
set_rpe
session_rpe
bodyweight_kg_at_session
```

`bodyweight_kg_at_session` phải là snapshot theo thời điểm nếu muốn đánh giá ảnh hưởng thay đổi cân nặng. Không nên lấy cân nặng hiện tại rồi gắn ngược cho toàn bộ lịch sử mà không đánh dấu đây là dữ liệu suy diễn.

### 6.2 Ground truth cần thu thập

Không dùng điểm Recovery hiện tại làm nhãn vì như vậy model chỉ học lại công thức đang cần kiểm chứng.

Nên thu thập các outcome độc lập:

```text
readiness_before_workout       1–10
energy_before_workout          1–10
soreness_by_muscle             0–10
sleep_quality                  1–10
sleep_duration
stress                         1–10
illness_or_injury              boolean
post_session_rpe               1–10
performance_delta              so với baseline cá nhân
```

`performance_delta` có thể dựa trên estimated 1RM, reps tại cùng mức tạ, mức tạ tại cùng RPE hoặc tỷ lệ hoàn thành volume dự kiến.

Ban đầu đánh giá readiness, soreness và performance delta riêng. Không tự cộng thành một điểm Recovery tổng hợp với trọng số chưa được kiểm chứng.

## 7. Khi nào dữ liệu Plato đủ để bắt đầu

Không quyết định chỉ bằng tổng số tài khoản. Dữ liệu phải có đủ chiều sâu theo thời gian và đủ outcome độc lập.

Các gate kỹ thuật tạm thời, cần điều chỉnh bằng learning curve:

1. **Feasibility:** ít nhất 50 người đồng ý tham gia, mỗi người có khoảng 8 tuần dữ liệu và check-in tương đối đều; chỉ dùng để kiểm tra pipeline.
2. **Candidate modeling:** khoảng 200 người, tối thiểu 12 tuần/người và ít nhất 12 buổi có outcome hợp lệ; đủ để thử model đơn giản và đánh giá theo user.
3. **Rollout validation:** ưu tiên 500 người trở lên, có tập user hoàn toàn độc lập và đủ đại diện theo giới tính, tuổi, mục tiêu và kinh nghiệm tập.

Các con số trên là gate vận hành, không phải ngưỡng khoa học cố định. Nếu learning curve vẫn tiếp tục cải thiện mạnh hoặc subgroup quá ít, phải tiếp tục thu thập.

## 8. Pipeline dự kiến

```powershell
python -m plato_recovery.cli prepare `
  --dataset plato `
  --input data/raw/plato_export `
  --output data/processed/plato.parquet

python -m plato_recovery.cli predict `
  --config configs/plato_baseline_v1.json `
  --input data/processed/plato.parquet `
  --output outputs/predictions.parquet

python -m plato_recovery.cli evaluate `
  --predictions outputs/predictions.parquet `
  --output outputs/evaluation.html
```

Mỗi prediction nên giữ cả kết quả và dữ liệu giải thích:

```text
user_id_pseudonymous
timestamp
muscle
raw_volume
relative_load
objective_intensity
effective_rpe
raw_fatigue
recovery_percentage
recovery_state
hours_to_ready
hours_to_full
model_version
config_hash
```

## 9. Phương pháp đánh giá

So sánh ít nhất các baseline sau:

1. Chỉ số giờ kể từ lần tập gần nhất.
2. Số giờ và số working set.
3. Số giờ, volume và RPE.
4. Công thức Plato hiện tại.
5. Candidate model cá nhân hóa.

Metric đề xuất:

- MAE/RMSE cho readiness và soreness;
- Spearman correlation cho thứ tự mức sẵn sàng;
- Brier score và calibration curve cho `ready/not ready`;
- false-green rate: model báo sẵn sàng nhưng outcome cho thấy chưa sẵn sàng;
- metric theo từng user và subgroup, không chỉ trung bình toàn dataset;
- khoảng tin cậy bằng bootstrap.

Chia dữ liệu:

- chia theo thời gian, không random ngày của cùng một người;
- có tập test gồm user chưa từng xuất hiện khi train;
- calibration và test tách riêng;
- dataset nhỏ dùng leave-one-user-out;
- mọi feature chỉ được dùng dữ liệu có trước thời điểm prediction.

Candidate chỉ được thay baseline khi cải thiện ổn định và không làm tăng false-green. Không chọn model chỉ vì một metric trung bình tốt hơn.

## 10. Dataset công khai dùng tạm cho pipeline

Ưu tiên:

- [SoccerMon](https://zenodo.org/records/10033832): training load, wellness và GPS của vận động viên bóng đá.
- [PMData](https://datasets.simula.no/pmdata/): Fitbit, session-RPE, sleep, readiness, soreness và stress.
- [FitRec/Endomondo](https://cseweb.ucsd.edu/~jmcauley/datasets/fitrec.html): lịch sử cardio nhiều user; giới hạn sử dụng học thuật.
- [PERSIST](https://zenodo.org/records/7437229): resistance training, RPE, ECG, HRV và IMU.
- [REST](https://zenodo.org/records/16937033): sleep, well-being, training load và hand-grip test.
- [HIFT modalities](https://doi.org/10.6084/m9.figshare.25858906): RPE, HR, HRV, lactate và CMJ.
- [Sport DB 2.0](https://data.mendeley.com/datasets/kzkjkt7mx2/1): ECG, HR, RR và breathing trong nhiều môn thể thao.
- [Competitive runners training log](https://research.rug.nl/en/datasets/replication-data-for-injury-prediction-in-competitive-runners-wit/): training log dài hạn của runner.
- [Microsoft RecoFit](https://github.com/microsoft/Exercise-Recognition-from-Wearable-Sensors): nhận dạng bài gym và đếm reps.
- [MM-Fit](https://mmfit.github.io/): workout, IMU, heart rate, pose và rep labels.

Bổ trợ:

- [GymStreak research data](https://www.gymstreak.com/research/how-lifters-train)
- [OpenPowerlifting](https://openpowerlifting.gitlab.io/opl-csv/bulk-csv.html)
- [MMASH](https://physionet.org/content/mmash/1.0.0/)
- [Fitbit Fitness Tracker Data](https://www.kaggle.com/datasets/arashnic/fitbit)
- [ExtraSensory](https://extrasensory.ucsd.edu/)
- [WISDM](https://archive.ics.uci.edu/dataset/507/wisdm%2Bsmartphone%2Band%2Bsmartwatch%2Bactivity%2Band%2Bbiometrics%2Bdataset)
- [PAMAP2](https://archive.ics.uci.edu/dataset/231/pamap2%2Bphysical%2Bactivity%2Bmonitoring)
- [MHEALTH](https://archive.ics.uci.edu/dataset/319/mhealth%2Bdataset.)
- [REALDISP](https://archive.ics.uci.edu/dataset/305/realdisp%2Bactivity%2Brecognition%2Bdataset)
- [UCI HAR](https://archive.ics.uci.edu/dataset/240/human%2Bactivity%2Brecognition%2Busing%2Bsmartphones)

Không dùng dataset không có provenance, protocol thu thập hoặc paper rõ ràng để chứng minh model chính xác. Dữ liệu tổng hợp chỉ được dùng để thử pipeline.

## 11. Lộ trình triển khai

### Mốc 1 — Python parity

- Tạo `recovery_model/`.
- Port công thức Dart hiện tại.
- Tạo golden fixtures và parity test.
- Chưa thay đổi kết quả hiển thị trong app.

### Mốc 2 — Dataset pipeline

- Tạo canonical schema.
- Viết adapter Plato, PMData và SoccerMon.
- Flatten session/set RPE.
- Báo cáo missing value, outlier và coverage theo user.
- Hoàn thành CLI `prepare`, `predict`, `evaluate`.

### Mốc 3 — Public-data benchmark

- Chạy baseline trên các phần dữ liệu có thể mapping hợp lệ.
- Xác định phần nào của công thức có bằng chứng và phần nào chưa thể kiểm chứng.
- Không dùng kết quả này để tuyên bố Recovery theo nhóm cơ đã được validation.

### Mốc 4 — Thu thập dữ liệu Plato

- Opt-in và consent rõ ràng.
- ID giả danh; không đặt email trong dataset nghiên cứu.
- Check-in trước buổi tập và outcome sau buổi tập.
- Snapshot cân nặng theo thời điểm nếu dùng làm feature.
- Cơ chế export và xóa dữ liệu.
- Không thu GPS nếu Recovery không cần.

### Mốc 5 — Candidate model

Bắt đầu bằng model dễ giải thích:

- regularized linear/logistic regression;
- hierarchical hoặc mixed-effects model theo user;
- calibration theo lịch sử cá nhân.

Chỉ thử model phức tạp hơn khi learning curve và residual analysis cho thấy baseline đơn giản không đủ.

### Mốc 6 — Shadow validation

- App vẫn hiển thị Plato baseline.
- Candidate chạy song song nhưng chưa tác động UI hoặc gợi ý.
- So prediction với outcome thực tế.
- Chỉ rollout khi vượt evaluation gate đã chốt trước.

## 12. Quyết định phải chốt trước khi thay công thức app

1. Python chỉ dùng offline cho nghiên cứu hay có backend inference; đề xuất ban đầu là offline research, Dart là production runtime.
2. Recovery cần dự đoán general readiness hay Recovery theo từng nhóm cơ; nhóm cơ đòi hỏi nhãn soreness/readiness theo nhóm cơ.
3. Cách snapshot cân nặng và cách phân biệt bodyweight với thiếu dữ liệu weight.
4. Consent, retention, quyền export/xóa dữ liệu nghiên cứu.
5. Gate đánh giá và false-green tolerance trước khi xem kết quả candidate.

Mọi thay đổi công thức production sau này phải cập nhật code, test, `UC18`, mapping liên quan và DOCX generated theo quy trình repository.
