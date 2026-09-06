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

3. Kök dizinde bir `.env` dosyası oluştur ve OpenWeatherMap API anahtarını ekle:

OPENWEATHER_API_KEY=senin_api_anahtarin

4. Uygulamayı çalıştır:

flutter run


## 👤 Geliştirici

Neşat Alperen Keremoğlu — Bilgisayar Mühendisliği öğrencisi
