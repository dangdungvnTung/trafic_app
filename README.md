# 🚦 Traffic App

Ứng dụng thông tin giao thông thời gian thực, xây dựng bằng **Flutter** với kiến trúc **GetX** (feature-first). Hỗ trợ bản đồ tương tác, chatbot AI, camera nhận diện và tìm kiếm địa điểm.

---

## Yêu cầu hệ thống

| Công cụ              | Phiên bản tối thiểu     |
| -------------------- | ----------------------- |
| Flutter SDK          | ≥ 3.10.0                |
| Dart SDK             | ≥ 3.10.0                |
| Xcode (iOS)          | ≥ 15.0                  |
| Android Studio / SDK | API level 21+           |
| CocoaPods (iOS)      | ≥ 1.13.0                |
| make                 | có sẵn trên macOS/Linux |
| Python3              | có sẵn trên macOS/Linux |

---

## Cài đặt từ A đến Z

### Bước 1 – Clone repository

```bash
git clone <repository-url>
cd traffic_app
```

---

### Bước 2 – Tạo file `.env`

File `.env` **không được commit** lên git. Tạo từ template:

```bash
cp .env.example .env
```

Mở `.env` và điền giá trị thực:

```dotenv
BASE_URL=https://your-api-server.com
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

> **Lấy Google Maps API Key:**
>
> 1. Vào [Google Cloud Console](https://console.cloud.google.com/)
> 2. Tạo project (hoặc chọn project có sẵn)
> 3. Bật các API sau: **Maps SDK for Android**, **Maps SDK for iOS**, **Places API**, **Geocoding API**
> 4. Vào **Credentials** → **Create Credentials** → **API Key**
> 5. Dán key vào `GOOGLE_MAPS_API_KEY` trong `.env`

---

### Bước 3 – Inject API key vào native config

Project sử dụng Makefile để tự động map key từ `.env` vào `AndroidManifest.xml` và `AppDelegate.swift`:

```bash
make inject-keys
```

Lệnh này sẽ:

- Điền `GOOGLE_MAPS_API_KEY` vào [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
- Điền `GOOGLE_MAPS_API_KEY` vào [ios/Runner/AppDelegate.swift](ios/Runner/AppDelegate.swift)
- Ẩn 2 file trên khỏi `git status` (dùng `skip-worktree`) để key thật không bị commit

> **Lưu ý:** Phải chạy lại `make inject-keys` mỗi khi clone repo lần đầu hoặc sau khi đổi key trong `.env`.

---

### Bước 4 – Cài đặt dependencies

```bash
flutter pub get
```

---

### Bước 5 – Cài đặt CocoaPods (iOS)

```bash
cd ios
pod install
cd ..
```

> Nếu gặp lỗi pod, thử:
>
> ```bash
> cd ios && pod repo update && pod install && cd ..
> ```

---

### Bước 6 – Chạy ứng dụng

```bash
# Xem danh sách thiết bị khả dụng
flutter devices

# Chạy trên thiết bị/simulator cụ thể
flutter run -d <device-id>

# Hoặc để Flutter tự chọn
flutter run
```

---

## Cấu trúc thư mục

```
lib/
├── data/
│   ├── models/          # Data models (toJson / fromJson)
│   ├── repositories/    # Xử lý API calls, error handling
│   └── services/        # ApiService (Dio + auto token refresh)
├── modules/             # Feature modules (GetX pattern)
│   ├── home/            # Bottom navigation shell
│   ├── dashboard/       # Trang chủ - feed bài viết
│   ├── map/             # Bản đồ Google Maps + traffic markers
│   ├── camera/          # Camera nhận diện biển báo
│   ├── discovery/       # Tìm kiếm & khám phá
│   ├── chatbot/         # Chatbot AI
│   ├── login/
│   ├── signup/
│   └── profile/
├── routes/              # AppPages + AppRoutes (GetX routing)
├── services/            # StorageService, AssetsService, LocalizationService
├── theme/               # AppTheme (màu sắc, typography)
├── widgets/             # Shared UI components
└── main.dart
```

---

## Biến môi trường

| Biến                  | Mô tả                                             | Bắt buộc |
| --------------------- | ------------------------------------------------- | -------- |
| `BASE_URL`            | URL backend API                                   | ✅       |
| `GOOGLE_MAPS_API_KEY` | Google Maps API Key (Places, Geocoding, Maps SDK) | ✅       |

---

## Makefile commands

| Lệnh               | Mô tả                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------- |
| `make inject-keys` | Inject key từ `.env` vào native configs + ẩn khỏi git                                 |
| `make reset-keys`  | Khôi phục placeholder + re-track files (dùng trước khi commit thay đổi 2 file native) |
| `make setup`       | Chạy 1 lần khi setup repo lần đầu – commit placeholder baseline                       |
| `make show-keys`   | Xem key hiện tại ở `.env`, `AndroidManifest.xml`, `AppDelegate.swift`                 |

---

## Các lỗi thường gặp

### Bản đồ hiện màu xám (không có tiles)

- Chưa chạy `make inject-keys` sau khi clone
- API Key chưa bật **Maps SDK for Android / iOS** trong Google Cloud Console
- Hết quota hoặc key bị restrict theo bundle ID

### `dotenv` throw exception khi khởi động

- File `.env` chưa được tạo → chạy `cp .env.example .env` và điền giá trị

### iOS build lỗi `GoogleMaps not found`

```bash
cd ios && pod install && cd ..
flutter clean && flutter run
```

### Android build lỗi `Gradle sync failed`

```bash
flutter clean
flutter pub get
flutter run
```

### Auto-login không hoạt động

- Kiểm tra `BASE_URL` trong `.env` có đúng endpoint backend không
- Xem log: `flutter run` và quan sát `Auto login failed:` trong console

---

## Luồng xác thực

```
main.dart
  └─ Có credentials trong StorageService?
       ├─ Có → Auto-login → thành công → HOME
       │                  → thất bại  → LOGIN
       └─ Không → LOGIN
```

`ApiService` tự động:

1. Đính kèm Bearer token vào mọi request
2. Khi nhận 401 → tự re-login với credentials đã lưu
3. Retry request gốc với token mới hoặc redirect về LOGIN

---

## Build production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (cần Xcode + Apple Developer account)
flutter build ios --release
```
