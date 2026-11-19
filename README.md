# MOVI – แอปจองตั๋วภาพยนตร์ (cinema_app)

แอปจองตั๋วหนังพัฒนาด้วย Flutter ผู้ใช้เข้าสู่ระบบด้วยอีเมล ดูรายการหนังและรายละเอียดพร้อมตัวอย่างหนัง เลือกรอบฉายและที่นั่ง ชำระเงินพร้อมใช้โค้ดส่วนลด แล้วรับตั๋วเป็น QR Code ข้อมูลทั้งหมดเก็บบน Firebase (Authentication + Cloud Firestore)

🌐 **เว็บที่ deploy:** https://natcha-runsri.github.io/Movie_App/

รายวิชา Application Development for Mobile Devices 

## ฟีเจอร์หลัก

- **สมัครสมาชิก / เข้าสู่ระบบ** ด้วยอีเมลและรหัสผ่าน (Firebase Authentication) แอปจำสถานะล็อกอินไว้และพาไปหน้าแรกอัตโนมัติ
- **หน้าแรก** มีแบนเนอร์แบบเลื่อน ช่องค้นหา และรายการหนังแนวนอน
- **รายการหนัง** เรียงตามล่าสุด/เก่าสุด และกรองเฉพาะหนังที่กด Favorite
- **รายละเอียดหนัง** เล่นตัวอย่างหนังจาก YouTube (`youtube_player_iframe`) หรือวิดีโอ (`chewie` + `video_player`) และกด Favorite ได้
- **จองตั๋ว** เลือกโรงภาพยนตร์ วัน และรอบฉาย แล้วเลือกที่นั่งตามประเภทซึ่งมีราคาต่างกัน
- **ชำระเงิน** เป็นการจำลอง
- **ตั๋วของฉัน** แสดงตั๋วเป็น QR Code (`qr_flutter`) และดู **ประวัติการจองตั๋ว** ได้
- **โปรโมชัน** และ **การแจ้งเตือน** โดยซ่อนหรืออ่านแล้วได้
- **โปรไฟล์ผู้ใช้** แก้อีเมลและเบอร์โทร และเลือกรูปอวาตาร์
- หน้า **ติดต่อเรา** และ **ผู้จัดทำ**

## Tech Stack

| ส่วน | รายละเอียด |
|---|---|
| Framework | Flutter (pubspec.lock ระบุ `flutter >= 3.29.0`; CI ใช้ 3.29.3) |
| ภาษา | Dart SDK `^3.7.2` |
| Backend | Firebase Core `^4.0.0`, Firebase Auth `^6.0.2`, Cloud Firestore `^6.0.0` |
| วิดีโอ | `youtube_player_iframe`, `chewie`, `video_player` |
| อื่น ๆ | `qr_flutter`, `intl`, `month_picker_dialog`, `url_launcher`, `font_awesome_flutter`, `shared_preferences`, `flutter_secure_storage` |
| Deploy | GitHub Actions → GitHub Pages |

## โครงสร้างโฟลเดอร์

```
Movie_App/
├── .github/workflows/pages.yml   # CI: build เว็บแล้ว deploy ขึ้น GitHub Pages
├── images/                       # รูปโลโก้ รูปโปรไฟล์ และอวาตาร์ (avatar_profile/)
├── lib/
│   ├── main.dart                 # จุดเริ่มแอป: initialize Firebase แล้วเลือกหน้า Login หรือ Home
│   ├── add_data.dart             # สคริปต์ seed ข้อมูลที่นั่ง (ปัจจุบันถูก comment ไว้)
│   ├── bar_icon/                 # หน้าหลักในแถบเมนู: Home, Movies, Promotion, More, Notification
│   ├── database/                 # model, service และ helper ที่ติดต่อ Firestore/Auth รวมถึง firebase_options.dart
│   ├── detail/                   # รายละเอียดหนัง, จอง, เลือกที่นั่ง, ชำระเงิน, ตั๋วของฉัน
│   ├── icon_more_detail/         # โปรไฟล์ผู้ใช้, ประวัติ, ติดต่อเรา, ผู้จัดทำ
│   └── login&register_page/      # หน้าเข้าสู่ระบบและสมัครสมาชิก
├── web/                          # ไฟล์สำหรับ Flutter Web (index.html, manifest, icons)
├── android/ ios/ macos/ linux/ windows/
├── firebase.json
└── pubspec.yaml
```

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) เวอร์ชัน 3.29 ขึ้นไป (Dart 3.7.2 ขึ้นไป)
- Google Chrome สำหรับรันบนเว็บ
- Android Studio + Android SDK หรืออุปกรณ์ Android สำหรับรันบนมือถือ (และ Xcode สำหรับ iOS บน macOS)
- โปรเจกต์ Firebase ของตัวเอง (ดูหัวข้อ [การตั้งค่า Firebase](#การตั้งค่า-firebase))

## วิธีติดตั้งและรัน

```bash
git clone https://github.com/natcha-runsri/Movie_App.git
cd Movie_App
flutter pub get
```

**รันบนเว็บ (Chrome)**

```bash
flutter run -d chrome
```

> `.vscode/launch.json` มีคอนฟิกให้รันบน Chrome ที่พอร์ต 40001 (`--web-port 40001`)

**รันบนมือถือ** (เปิด emulator หรือเสียบอุปกรณ์ก่อน)

```bash
flutter devices          # ดู device id
flutter run -d <device-id>
```

## การตั้งค่า Firebase

แอปใช้ **Firebase Authentication** (อีเมล/รหัสผ่าน) และ **Cloud Firestore** ค่าการเชื่อมต่ออยู่ใน `lib/database/firebase_options.dart` และ `android/app/google-services.json` (สร้างจาก FlutterFire CLI)

ถ้าต้องการใช้โปรเจกต์ Firebase ของตัวเอง:

1. สร้างโปรเจกต์ใน [Firebase Console](https://console.firebase.google.com/)
2. เปิด **Authentication → Sign-in method → Email/Password**
3. สร้างฐานข้อมูล **Cloud Firestore**
4. ติดตั้งและรัน FlutterFire CLI เพื่อสร้างไฟล์ config ใหม่
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
5. ถ้าจะใช้บนเว็บ GitHub Pages ให้เพิ่ม `natcha-runsri.github.io` ใน **Authentication → Settings → Authorized domains**

Collection ที่แอปใช้ใน Firestore: `movie`, `cinema`, `showtime`, `screens`, `seats`, `bookings`, `promotion`, `profile` (มี sub-collection `favorites`)

<!-- TODO: repo ยังไม่มีไฟล์ firestore.rules ควรเพิ่มและอธิบาย Security Rules ที่ใช้จริง -->
### เตรียมข้อมูลตั้งต้นใน Firestore

สร้างข้อมูลใน Cloud Firestore หลังจากตั้งค่า Firebase แล้ว โดยใช้ชื่อ collection และ field ให้ตรงตามที่แอปอ่าน (ชื่อ field แยกตัวพิมพ์เล็ก-ใหญ่) เอกสารที่มี ID อ้างอิงกันควรสร้างตามลำดับนี้:

1. **หนัง — `movie/{movieId}`**: เพิ่มเอกสารจาก Firebase Console หรือหน้าเพิ่มข้อมูลของแอป โดยมี `name`, `description`, `images`, `time` (นาที), `date` (ชนิด Timestamp), `type` (array), `cast` (array), `cast_images` (array), `status`, `trailer`, `director` (array), `direc_images` (array) และ `recommend` (array) ใช้ document ID นี้เป็น `movieId` ในรอบฉาย
2. **โรง — `cinema/{cinemaId}`**: กำหนด ID เองเพื่อใช้อ้างอิง แล้วเพิ่ม `name`, `address`, `phone`, `screen` (จำนวนห้อง) และ `location` (ชนิด GeoPoint; เว้นได้หากไม่มีพิกัด)
3. **รอบฉาย — `showtime/{slotId}`**: สร้างหนึ่งเอกสารต่อหนึ่งหนัง หนึ่งโรง หนึ่งวัน และหนึ่งเวลา แนะนำ ID รูปแบบ `c_{cinemaId}_m_{movieId}_{YYYY-MM-DD}_{HHmm}` เช่น `c_central_m_movie01_2026-12-01_1400` โดยมี `movieId`, `movieTitle`, `cinemaId`, `cinemaName`, `dateKey` (ข้อความ `YYYY-MM-DD`), `time` (`HH:mm`) และ `showDate` (Timestamp ของวันนั้นเวลา 00:00 น.) ให้ค่า ID ตรงกับเอกสารหนังและโรง
4. **ห้องฉายในรอบ — `showtime/{slotId}/screens/{screenId}`**: ใช้ ID ห้อง เช่น `1`; เพิ่ม `screenId`, `audio` (`TH` หรือ `EN`), `format` (`2D` หรือ `3D`), `basePrice` (ตัวเลข), `movieId`, `cinemaId`, `dateKey` และ `time` (array ของเวลา `HH:mm`) แม้เอกสารรอบจะมีเวลาเดียว ให้ใส่เวลานั้นใน array นี้ด้วย เพราะหน้าเลือกที่นั่งค้นเอกสาร `screens`
5. **ที่นั่ง — `showtime/{slotId}/screens/{screenId}/seats/{row}`**: สร้างเอกสารหนึ่งรายการต่อแถว โดยใช้ ID แถว เช่น `A`; ใส่ `row`, `type` (`Standard`, `Premium` หรือ `VIP`), `price`, `seatId` (array ของเลขที่นั่งเป็นข้อความ เช่น `01` ถึง `14`) และ `status` (array ความยาวเท่ากัน โดยเริ่มทุกตำแหน่งเป็น `unreserved`)

ตัวอย่างแผนผัง:

```text
movie/movie01
cinema/central
showtime/c_central_m_movie01_2026-12-01_1400
  screens/1
    seats/A
    seats/B
```

เริ่มเตรียมข้อมูลด้วยหนังและโรงก่อน แล้วใช้ ID ของทั้งสองรายการสร้างรอบฉาย จากนั้นสร้างห้องและแถวที่นั่งใต้รอบนั้น หากมีหลายเวลา ให้สร้างรอบฉายแยกต่อเวลาเพื่อให้ `dateKey`, `time` และ `slotId` ระบุรอบได้ชัดเจน ตรวจสอบให้ชื่อ collection เป็น `showtime` (เอกพจน์) และ subcollection เป็น `screens` และ `seats` ตามตัวอย่าง

## วิธี Build

**เว็บ**

```bash
flutter build web --release --base-href "/Movie_App/"
# ผลลัพธ์อยู่ที่ build/web/
```

**Android APK**

```bash
flutter build apk --release
# ผลลัพธ์อยู่ที่ build/app/outputs/flutter-apk/app-release.apk
```

<!-- TODO: ตอนนี้ release build ใช้ debug signing ตามค่าเริ่มต้น ถ้าจะเผยแพร่จริงต้องตั้งค่า keystore (ห้าม commit key.properties และไฟล์ .jks) -->

## การ Deploy อัตโนมัติผ่าน GitHub Actions

ไฟล์ [`.github/workflows/pages.yml`](.github/workflows/pages.yml) ทำงานเมื่อ push เข้า branch `main` หรือสั่งรันเองจากแท็บ Actions (workflow_dispatch)

1. checkout โค้ด
2. ติดตั้ง Flutter 3.29.3 ด้วย `subosito/flutter-action`
3. `flutter pub get`
4. `flutter build web --release --base-href "/Movie_App/"`
5. อัปโหลด `build/web` ด้วย `actions/upload-pages-artifact` แล้ว deploy ด้วย `actions/deploy-pages`

ตั้งค่าครั้งแรก: ที่ repo ไปที่ **Settings → Pages → Build and deployment → Source** แล้วเลือก **GitHub Actions**

## ผู้พัฒนา

- นายทัตพงส์ ทองยวง
- นางสาวณัชชา รุนศรี


