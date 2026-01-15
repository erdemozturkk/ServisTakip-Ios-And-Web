# Servis Takip Uygulaması - Mobil (Flutter)

## 📱 Proje Hakkında

Kullanıcıların okul veya iş servislerini kolayca takip edebilmesi, günlük rotaların otomatik olarak oluşturulması ve kullanıcıların "bugün servise binmeyeceğim" gibi bildirimlerde bulunarak rotanın dinamik biçimde yeniden düzenlenmesini sağlayan mobil uygulama.

## 🎯 Özellikler

### Kullanıcı Yönetimi
- ✅ Kullanıcı girişi ve kayıt (Yolcu, Şoför, Yönetici)
- ✅ Rol bazlı yetkilendirme
- ✅ Profil yönetimi

### Yolcu Özellikleri
- 🔄 Günlük/haftalık rezervasyon oluşturma
- 🗺️ Harita üzerinden durak seçimi
- 📍 Canlı servis takibi
- 🔔 Bildirim sistemi (servis yaklaşırken, gecikme vb.)
- ✖️ "Servise binmeyeceğim" seçeneği

### Şoför Özellikleri
- 🗺️ Günlük rota görüntüleme
- 📍 Canlı konum paylaşımı
- ✅ Durak tamamlama
- 👥 Yolcu listesi

### Yönetici Özellikleri
- 📊 Dashboard (istatistikler, doluluk oranları)
- 🚌 Servis yönetimi
- 👥 Kullanıcı yönetimi
- 🚗 Araç yönetimi
- 🗺️ Tüm servislerin canlı takibi

## 📁 Proje Yapısı

```
lib/
├── main.dart                      # Ana uygulama giriş noktası
├── models/                        # Veri modelleri
│   ├── user_model.dart           # Kullanıcı modeli
│   ├── service_model.dart        # Servis modeli
│   ├── route_model.dart          # Rota modeli
│   ├── stop_model.dart           # Durak modeli
│   ├── reservation_model.dart    # Rezervasyon modeli
│   ├── notification_model.dart   # Bildirim modeli
│   └── vehicle_model.dart        # Araç modeli
├── services/                      # API servisleri
│   ├── auth_service.dart         # Kimlik doğrulama servisi
│   ├── service_api_service.dart  # Servis API servisi
│   ├── reservation_service.dart  # Rezervasyon servisi
│   └── notification_service.dart # Bildirim servisi
├── pages/                         # Uygulama sayfaları
│   ├── auth/                     # Kimlik doğrulama sayfaları
│   │   ├── login_page.dart
│   │   └── register_page.dart
│   ├── passenger/                # Yolcu sayfaları
│   │   └── passenger_dashboard.dart
│   ├── driver/                   # Şoför sayfaları
│   │   └── driver_dashboard.dart
│   ├── admin/                    # Yönetici sayfaları
│   │   └── admin_dashboard.dart
│   └── map_page.dart            # Harita sayfası
└── utils/                        # Yardımcı dosyalar
    └── constants.dart           # Sabitler
```

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK (3.9.2+)
- Dart SDK (3.9.2+)
- Android Studio / VS Code
- Google Maps API Key

### Adımlar

1. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

2. **Google Maps API Key'inizi ayarlayın:**
   - `lib/utils/constants.dart` dosyasını açın
   - `googleMapsApiKey` değişkenine API key'inizi yazın

3. **Backend API URL'inizi ayarlayın:**
   - `lib/utils/constants.dart` dosyasını açın
   - `apiBaseUrl` değişkenine backend URL'inizi yazın

4. **Uygulamayı çalıştırın:**
```bash
flutter run
```

## 📦 Kullanılan Paketler

### UI & Maps
- `google_maps_flutter` - Harita görüntüleme
- `flutter_svg` - SVG desteği
- `sliding_up_panel` - Kaydırılabilir panel

### Location
- `location` - Konum servisleri
- `geolocator` - Konum takibi
- `geocoding` - Adres dönüşümü

### State Management
- `provider` - Durum yönetimi

### Network & API
- `http` - HTTP istekleri
- `dio` - Gelişmiş HTTP client

### Notifications
- `firebase_core` - Firebase temel
- `firebase_messaging` - Push bildirimleri
- `flutter_local_notifications` - Yerel bildirimler

### Real-time
- `signalr_netcore` - SignalR bağlantısı

### Storage
- `shared_preferences` - Yerel veri saklama

### Utils
- `intl` - Tarih/saat formatlama
- `url_launcher` - URL açma

## 🔧 Yapılandırma

### API Ayarları
`lib/utils/constants.dart` dosyasında aşağıdaki ayarları yapılandırın:

```dart
static const String apiBaseUrl = 'http://your-api-url/api';
static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
static const String signalRHubUrl = 'http://your-api-url/hubs/service';
```

## 🏗️ Backend Gereksinimleri

Uygulama aşağıdaki API endpoint'lerini beklemektedir:

### Authentication
- `POST /api/auth/login` - Kullanıcı girişi
- `POST /api/auth/register` - Kullanıcı kaydı
- `GET /api/auth/me` - Kullanıcı bilgileri

### Services
- `GET /api/services/today` - Günlük servisler
- `GET /api/services/my` - Kullanıcının servisi
- `GET /api/services/{id}/route` - Servis rotası
- `PUT /api/services/{id}/status` - Servis durumu güncelleme

### Reservations
- `GET /api/reservations/my` - Rezervasyonlarım
- `POST /api/reservations` - Rezervasyon oluştur
- `PUT /api/reservations/{id}` - Rezervasyon güncelle
- `DELETE /api/reservations/{id}` - Rezervasyon iptal

### Notifications
- `GET /api/notifications` - Bildirimleri getir
- `PUT /api/notifications/{id}/read` - Okundu işaretle

## 🎨 Tema

Uygulama Material Design 3 (Material You) kullanmaktadır.

## 📝 Yapılacaklar

- [ ] Yolcu paneli sayfalarını tamamla
- [ ] Şoför paneli sayfalarını tamamla
- [ ] Yönetici paneli sayfalarını tamamla
- [ ] Harita entegrasyonunu tamamla
- [ ] SignalR real-time bağlantısını ekle
- [ ] Firebase Cloud Messaging yapılandır
- [ ] Unit testler yaz
- [ ] Widget testleri yaz

## 🔐 Güvenlik

- Token bazlı kimlik doğrulama (JWT)
- Şifreler güvenli şekilde backend'de saklanmalı
- API istekleri HTTPS üzerinden yapılmalı

## 📄 Lisans

Bu proje özel bir projedir.

## 👥 Geliştirici

Erdem Öztürk

---

**Not:** Bu proje hala geliştirme aşamasındadır. Backend API'nin hazır olması gerekmektedir.
