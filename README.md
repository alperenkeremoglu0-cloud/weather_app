# 🌤️ Hava Durumu Uygulaması

Flutter ile geliştirilmiş, gerçek zamanlı verilerle çalışan bir hava durumu uygulaması. Bu proje, mobil uygulama geliştirmeyi öğrenirken sıfırdan inşa edildi.

## ✨ Özellikler

- 🔍 Şehir adına göre anlık hava durumu araması
- 📍 GPS ile konum bazlı otomatik hava durumu
- 📅 5 günlük hava durumu tahmini
- ⏰ Bugüne özel saatlik tahmin (gece 06:00'a kadar)
- ⭐ Favori şehirleri kaydetme ve tek tıkla erişim
- 🕐 Arama geçmişi ve akıllı öneri listesi
- 🌙 Karanlık mod desteği
- 💧 Nem, rüzgar hızı ve hissedilen sıcaklık bilgileri
- 🎨 Hava durumuna göre değişen dinamik renkler ve ikonlar

## 🛠️ Kullanılan Teknolojiler

- **Flutter & Dart** — Uygulama geliştirme
- **OpenWeatherMap API** — Hava durumu verileri
- **Geolocator** — GPS konum servisleri
- **Shared Preferences** — Yerel veri saklama (favoriler, geçmiş)
- **flutter_dotenv** — API anahtarı güvenliği

## 🚀 Kurulum

1. Bu repository'yi klonla:
git clone https://github.com/alperenkeremoglu0-cloud/weather_app.git

2. Bağımlılıkları yükle:
flutter pub get

3. [openweathermap.org](https://openweathermap.org/api) adresinden ücretsiz bir API anahtarı al.

4. Proje kök dizininde bir `.env` dosyası oluştur ve şu satırı ekle:
OPENWEATHER_API_KEY=senin_api_anahtarin

5. Bir Android emulator başlat veya telefonunu bağla, sonra uygulamayı çalıştır:
flutter run

**Not:** Flutter SDK'nın ve Android geliştirme ortamının (Android Studio) kurulu olması gerekir.


## 👤 Geliştirici

Neşat Alperen Keremoğlu — Bilgisayar Mühendisliği öğrencisi
