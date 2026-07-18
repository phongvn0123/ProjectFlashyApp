---
phase: 0
slug: platform-spike
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-18
---

# Phase 0 — Validation Strategy

> Hợp đồng kiểm chứng cho Phase 0, dùng để lấy feedback trong lúc execute.
>
> **Bối cảnh:** Phase 0 là spike dùng-một-lần nhằm chứng minh Firebase + `sqflite`
> chạy được trên Android emulator. Đây **không phải** phase có unit test — bằng chứng
> là chuỗi PASS/FAIL in ra console cộng với ảnh chụp màn hình. Xem
> `00-RESEARCH.md` mục `## Validation Architecture` để biết nguồn gốc bảng dưới.
>
> **Phạm vi:** Android-only. FND-02 (Windows desktop) **đã bị rút** ngày 2026-07-18 —
> không kiểm chứng bất cứ thứ gì trên Windows.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual + logged assertion (con người đọc chuỗi `[SPIKE] ... PASS/FAIL` trong console) |
| **Config file** | none — spike không có test framework; `flutter analyze` là cổng tĩnh duy nhất |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `firebase emulators:start --only auth,firestore --project demo-spike-project` (terminal riêng) rồi `flutter run -d android` |
| **Estimated runtime** | ~15s cho `flutter analyze`; ~90s cho lần chạy emulator đầu tiên |

---

## Sampling Rate

- **After every task commit:** Chạy `flutter analyze` — phải sạch, không lỗi compile.
- **After every plan wave:** Chạy `flutter analyze`; từ Wave 2 trở đi chạy thêm `flutter run -d android` để xác nhận app còn khởi động được.
- **Before `/gsd:verify-work`:** Cả hai dòng `[SPIKE] SQLITE PASS` và `[SPIKE] FIREBASE PASS` phải xuất hiện trong log đã lưu.
- **Max feedback latency:** ~15 giây (`flutter analyze`); ~90 giây cho vòng lặp đầy đủ trên emulator.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 00-01-* | 01 | 1 | FND-01 | — | `google-services.json` nằm trong `.gitignore` trước khi commit đầu tiên | static | `flutter analyze` | ❌ W0 | ⬜ pending |
| 00-02-* | 02 | 2 | FND-03 | T-0-04 | `sqflite` mở DB trong thư mục app-private; không override `databaseFactory` | logged | `flutter run -d android` → `[SPIKE] SQLITE PASS` | ❌ W0 | ⬜ pending |
| 00-02-* | 02 | 2 | FND-04 | T-0-01, T-0-02 | Cleartext chỉ bật cho debug build, chỉ tới loopback `10.0.2.2` | logged | `flutter run -d android` → `[SPIKE] FIREBASE PASS` | ❌ W0 | ⬜ pending |
| 00-03-* | 03 | 3 | FND-01, FND-03, FND-04 | T-0-05 | Tắt tiến trình `firebase emulators:start` sau khi thu log | manual | quan sát + lưu log | ❌ W0 | ⬜ pending |
| 00-04-* | 04 | 4 | FND-01..04 | T-0-03 | `grep` không thấy pattern `AIza*` trong code commit | manual | `grep -rn "AIza" spike_platform/lib/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*File Exists `❌ W0` = file chưa tồn tại, sẽ được tạo trong wave tương ứng.*

---

## Wave 0 Requirements

Spike bắt đầu từ con số 0 nên **mọi** artifact kiểm chứng đều là Wave 0 gap:

- [ ] `spike_platform/` — Flutter project scaffold, Android-only (không tạo target Windows)
- [ ] `spike_platform/lib/sqlite_service.dart` — phủ FND-03 (round-trip `sqflite`)
- [ ] `spike_platform/lib/firebase_service.dart` — phủ FND-04 (Firebase Auth + Firestore)
- [ ] `spike_platform/lib/main.dart` — gộp hai service, tự chạy khi khởi động, in kết quả ra console
- [ ] `spike_platform/.gitignore` — chặn `google-services.json` trước commit đầu tiên
- [ ] Android Emulator dùng **Google APIs** system image — bắt buộc cho Firebase Auth (ảnh AOSP thuần **không** có Google Play Services)
- [ ] `firebase-tools` cài global + `firebase emulators:start` chạy được

*Không cần cài thêm test framework — spike không có automated test suite theo thiết kế.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App mở được cửa sổ trên emulator, không crash | FND-01 | Cần mắt người xác nhận UI render; không có widget test trong spike | Chạy `flutter run -d android`, xác nhận app hiện màn hình spike và không văng exception |
| Ảnh chụp màn hình làm bằng chứng cho SPIKE-FINDINGS.md | FND-01, FND-03, FND-04 | Bằng chứng dạng hình ảnh, không thể assert bằng code | Chụp màn hình spike screen đang hiển thị cả hai dòng kết quả PASS |
| Emulator system image có Google Play Services | FND-04 | Thuộc tính môi trường, không phải thuộc tính của code | Android Studio → AVD Manager → xác nhận cột "Target" ghi *Google APIs* |
| Không còn dấu vết `sqflite_common_ffi` / `databaseFactoryFfi` | FND-03 | Kiểm tra hồi quy chống lại các plan cũ đã lỗi thời | `grep -rn "sqflite_common_ffi\|databaseFactoryFfi" spike_platform/` phải rỗng |

---

## Validation Sign-Off

- [ ] Mọi task có `<automated>` verify hoặc được khai báo là Wave 0 dependency
- [ ] Sampling continuity: không có 3 task liên tiếp thiếu automated verify
- [ ] Wave 0 phủ hết các mục MISSING ở trên
- [ ] Không dùng cờ watch-mode
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` được set trong frontmatter

**Approval:** pending
