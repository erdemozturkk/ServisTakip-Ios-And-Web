# Servis Takip API

ASP.NET Core Web API + SignalR + MySQL tabanlı servis takip sistemi backend'i.

## Özellikler

- ✅ JWT Authentication
- ✅ Entity Framework Core + MySQL
- ✅ SignalR ile gerçek zamanlı konum takibi
- ✅ Redis Cache desteği (opsiyonel)
- ✅ RESTful API endpoints

## Kurulum

### 1. Gereksinimler
- .NET 8.0 SDK
- MySQL Server
- (Opsiyonel) Redis Server

### 2. Paketleri Yükle
```bash
cd c:\Users\Erdem\Desktop\servisTakip\api\ServisTakipAPI
dotnet restore
```

### 3. Veritabanı ve Güvenlik Ayarları

**ÖNEMLİ:** Hassas bilgiler Git'e eklenmemelidir!

#### Yapılandırma Dosyalarını Hazırla

1. **appsettings.Development.json oluştur** (yerel geliştirme için):
```bash
cp appsettings.example.json appsettings.Development.json
```

2. **appsettings.Development.json içine gerçek değerlerinizi yazın**:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Information"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=127.0.0.1;Port=3306;Database=ServisTakip;Uid=root;Pwd=YOUR_ACTUAL_MYSQL_PASSWORD;",
    "Redis": "localhost:6379"
  },
  "Jwt": {
    "SecretKey": "YOUR_STRONG_JWT_SECRET_KEY_AT_LEAST_32_CHARS_LONG",
    "Issuer": "ServisTakipAPI",
    "Audience": "ServisTakipApp"
  }
}
```

**Not:** `appsettings.Development.json` `.gitignore` ile korunuyor ve Git'e eklenmeyecek.

#### Alternatif: User Secrets (Önerilen)

Daha güvenli bir yöntem için .NET User Secrets kullanabilirsiniz:

```bash
# User secrets başlat
dotnet user-secrets init

# MySQL şifresini ekle
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=127.0.0.1;Port=3306;Database=ServisTakip;Uid=root;Pwd=YOUR_PASSWORD;"

# JWT secret ekle
dotnet user-secrets set "Jwt:SecretKey" "YOUR_STRONG_JWT_SECRET_KEY"
```

User secrets sadece geliştirme ortamında çalışır ve Git'e asla eklenmez.

#### Production Ortamı

Production'da environment variables kullanın:

**Linux/macOS:**
```bash
export ConnectionStrings__DefaultConnection="Server=prod-server;Port=3306;Database=ServisTakip;Uid=app_user;Pwd=SECURE_PASSWORD;"
export Jwt__SecretKey="PRODUCTION_JWT_SECRET_KEY_VERY_STRONG"
```

**Windows:**
```cmd
set ConnectionStrings__DefaultConnection=Server=prod-server;Port=3306;Database=ServisTakip;Uid=app_user;Pwd=SECURE_PASSWORD;
set Jwt__SecretKey=PRODUCTION_JWT_SECRET_KEY_VERY_STRONG
```

**Docker:**
```yaml
environment:
  - ConnectionStrings__DefaultConnection=Server=db;Port=3306;Database=ServisTakip;Uid=root;Pwd=${MYSQL_PASSWORD}
  - Jwt__SecretKey=${JWT_SECRET}
```

### 4. Uygulamayı Çalıştır
```bash
dotnet run
```

API: `https://localhost:5001`
Swagger: `https://localhost:5001/swagger`

## API Endpoints

### Authentication
- `POST /api/auth/login` - Giriş yap
- `POST /api/auth/register` - Kayıt ol

### Routes (Rotalar)
- `GET /api/routes/today` - Bugünün rotaları
- `GET /api/routes/{id}/stops` - Rota durakları
- `PUT /api/routes/{id}/status` - Rota durumu güncelle
- `PUT /api/routes/stops/{id}/arrive` - Durağa varış bildir

### Reservations (Rezervasyonlar)
- `GET /api/reservations/my` - Rezervasyonlarım
- `POST /api/reservations` - Rezervasyon oluştur
- `DELETE /api/reservations/{id}` - Rezervasyon iptal et

### Locations (Konumlar)
- `GET /api/locations/{vehicleId}` - Araç konumu al (cache'ten)

## SignalR Hub

### Location Hub: `/hubs/location`

**Şoför tarafından gönderilen:**
```javascript
hub.invoke("UpdateLocation", vehicleId, latitude, longitude);
hub.invoke("UpdateRouteStatus", routeId, status);
hub.invoke("NotifyStopArrival", routeId, stopId);
```

**İstemci tarafından dinlenen:**
```javascript
hub.on("ReceiveLocationUpdate", (location) => { });
hub.on("ReceiveRouteStatusUpdate", (update) => { });
hub.on("ReceiveStopArrival", (info) => { });
```

## Veritabanı Yapısı

- `users` - Kullanıcılar (yolcu, şoför, admin)
- `vehicles` - Araçlar
- `stops` - Duraklar
- `daily_routes` - Günlük rotalar
- `route_stops` - Rota-durak ilişkisi
- `reservations` - Rezervasyonlar
- `vehicle_locations` - Araç konumları (log)

## Cache Stratejisi

- **Gerçek zamanlı konum**: Redis cache (10 dakika TTL)
- **SignalR**: Tüm bağlı istemcilere broadcast
- **MySQL**: Periyodik log kaydı

## Güvenlik

- **JWT Bearer token authentication** - Endpoint koruması
- **Password hashing (SHA256)** - Şifre güvenliği
- **CORS yapılandırması** - Cross-origin erişim kontrolü
- **Hassas bilgi koruması:**
  - `appsettings.Development.json`, `appsettings.Production.json` Git'e eklenmez (.gitignore)
  - Production'da environment variables kullanılmalı
  - Geliştirme için .NET User Secrets önerilir
  - API key'ler asla kod içine hard-coded edilmemeli

### Güvenlik Kontrol Listesi

✅ `appsettings.example.json` şablon olarak kullan  
✅ Gerçek şifreler sadece `appsettings.Development.json` içinde (Git'e eklenmez)  
✅ JWT SecretKey en az 32 karakter uzunluğunda olmalı  
✅ Production'da environment variables veya Azure Key Vault kullan  
✅ Database şifreleri güçlü ve benzersiz olmalı  
✅ Redis erişimi production'da şifreyle korunmalı
- Role-based authorization

## Flutter Entegrasyonu

Flutter uygulamasında `lib/utils/constants.dart` dosyasını güncelle:
```dart
static const String baseUrl = 'https://localhost:5001/api';
static const String signalRHub = 'https://localhost:5001/hubs/location';
```

## Geliştirme Notları

- Redis kullanmak için `Program.cs`'de yorum satırlarını aç
- Production'da HTTPS sertifikası ayarla
- JWT SecretKey'i güvenli bir yere taşı
