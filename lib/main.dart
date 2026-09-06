import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;  
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
void main() async {
  await dotenv.load(fileName: ".env");
  runApp(
    ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Color(0xFF1E1E2C),
          ),
          themeMode: currentMode,
          home: Scaffold(body: Center(child: WeatherHome())),
        );
      },
    ),
  );
}

class TempCounter extends StatefulWidget {
  @override
  State<TempCounter> createState() => _TempCounterState();
}

class _TempCounterState extends State<TempCounter> {
  double temp = 20.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Sıcaklık: $temp°C"),
        ElevatedButton(
          onPressed: () {
            setState(() {
              temp = temp + 1;
            });
          },
          child: Text("+"),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              temp = temp - 1;
            });
          },
          child: Text("-"),
        ),
      ],
      
    );
  }
}
class WeatherHome extends StatefulWidget{

    @override
    State<WeatherHome> createState()=> _WeatherHomeState();
}
class _WeatherHomeState extends State<WeatherHome>{
final TextEditingController cityController = TextEditingController();
final FocusNode cityFocusNode = FocusNode();
@override
void initState() {
  super.initState();
  loadHistory();
  loadInitialWeather();
  cityFocusNode.addListener(() {
  setState(() {});
});
}

Future<void> loadInitialWeather() async {
  setState(() {
    isLoading = true;
  });

  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  LocationPermission permission = await Geolocator.checkPermission();

  if (serviceEnabled &&
      (permission == LocationPermission.always || permission == LocationPermission.whileInUse)) {
    await fetchWeatherByLocation();
  } else {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('history');
    if (saved != null && saved.isNotEmpty) {
      await fetchWeather(saved[0]);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }
}
String cityName = "";
double temperature = 0;
List<String> searchHistory = [];
List<String> favorites = [];
List<dynamic> forecastList = [];
List<dynamic> hourlyList = [];
String description = "";
bool hasData = false;
String errorMessage = "";
bool isLoading = false;
bool showSuggestions = false;
String iconCode = "01d";
int humidity = 0;
double feelsLike = 0;
double windSpeed = 0;
IconData getWeatherIcon(String iconCode) {
  if (iconCode.startsWith('01')) return Icons.wb_sunny;
  if (iconCode.startsWith('02') || iconCode.startsWith('03') || iconCode.startsWith('04')) {
    return Icons.cloud;
  }
  if (iconCode.startsWith('09') || iconCode.startsWith('10')) return Icons.water_drop;
  if (iconCode.startsWith('11')) return Icons.flash_on;
  if (iconCode.startsWith('13')) return Icons.ac_unit;
  if (iconCode.startsWith('50')) return Icons.blur_on;
  return Icons.wb_cloudy;
}
List<Color> getWeatherGradient(String code) {
  if (code.startsWith('01')) return [Colors.orange[300]!, Colors.blue[300]!];
  if (code.startsWith('02') || code.startsWith('03') || code.startsWith('04')) {
    return [Colors.blueGrey[300]!, Colors.blueGrey[100]!];
  }
  if (code.startsWith('09') || code.startsWith('10')) return [Colors.grey[600]!, Colors.blueGrey[300]!];
  if (code.startsWith('11')) return [Colors.grey[800]!, Colors.deepPurple[300]!];
  if (code.startsWith('13')) return [Colors.lightBlue[100]!, Colors.white];
  if (code.startsWith('50')) return [Colors.grey[400]!, Colors.grey[200]!];
  return [Colors.blue[300]!, Colors.blue[100]!];
}
String getDayName(String dateTimeText) {
  DateTime date = DateTime.parse(dateTimeText);
  List<String> days = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
  return days[date.weekday - 1];
}
String getHourText(String dateTimeText) {
  DateTime date = DateTime.parse(dateTimeText);
  String hour = date.hour.toString().padLeft(2, '0');
  return "$hour:00";
}
Future<void> fetchWeather(String city, {bool addToHistory = true}) async {
  bool stillFetching = true;
  Future.delayed(Duration(milliseconds: 1500), () {
    if (stillFetching) {
      setState(() {
        isLoading = true;
      });
    }
  });
  try {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=tr"
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        cityName = data['name'];
        temperature = data['main']['temp'];
        description = data['weather'][0]['description'];
        iconCode = data['weather'][0]['icon'];
        humidity = data['main']['humidity'];
        feelsLike = data['main']['feels_like'];
        windSpeed = data['wind']['speed'];
        hasData = true;
        errorMessage = "";
      });
      if (addToHistory) {
        saveSearch(data['name']);
      }
      fetchForecast(city);
    } else {
      setState(() {
        hasData = false;
        errorMessage = "Şehir bulunamadı, tekrar deneyin";
        hourlyList = [];
        forecastList = [];
      });
    }
  } catch (e) {
    setState(() {
      hasData = false;
      errorMessage = "Bağlantı hatası, tekrar deneyin";
      hourlyList = [];
      forecastList = [];
    });
  } finally {
    stillFetching = false;
    setState(() {
      isLoading = false;
    });
  }
}
Future<void> fetchForecast(String city) async {
  final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
  final url = Uri.parse(
    "https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric&lang=tr"
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List<dynamic> allEntries = data['list'];

    DateTime now = DateTime.now();
DateTime tomorrow = now.add(Duration(days: 1));
DateTime cutoff = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 6, 0, 0);
List<dynamic> todayHours = allEntries.where((entry) {
  DateTime entryTime = DateTime.parse(entry['dt_txt']);
  return entryTime.isAfter(now) && entryTime.isBefore(cutoff)
      || entryTime.isAtSameMomentAs(cutoff);
}).toList();

    String today = DateTime.now().toIso8601String().substring(0, 10);
List<dynamic> dailyEntries = [];
Set<String> addedDates = {};
for (var entry in allEntries) {
  String entryDate = entry['dt_txt'].toString().substring(0, 10);
  if (entryDate == today) continue;
  if (!addedDates.contains(entryDate)) {
    dailyEntries.add(entry);
    addedDates.add(entryDate);
  }
}

    setState(() {
      hourlyList = todayHours;
      forecastList = dailyEntries;
    });
  }
}
  Future<void> fetchWeatherByLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        errorMessage = "Konum servisi kapalı";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          errorMessage = "Konum izni reddedildi";
        });
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
    await fetchWeatherByCoords(position.latitude, position.longitude);
  } catch (e) {
    setState(() {
      errorMessage = "Konum alınamadı, tekrar deneyin";
    });
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}
Future<void> fetchWeatherByCoords(double lat, double lon) async {
  bool stillFetching = true;
  Future.delayed(Duration(milliseconds: 1500), () {
    if (stillFetching) {
      setState(() {
        isLoading = true;
      });
    }
  });
  final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
  final url = Uri.parse(
    "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=tr"
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    setState(() {
      cityName = data['name'];
      temperature = data['main']['temp'];
      description = data['weather'][0]['description'];
      iconCode = data['weather'][0]['icon'];
      humidity = data['main']['humidity'];
feelsLike = data['main']['feels_like'];
windSpeed = data['wind']['speed'];
      hasData = true;
      errorMessage = "";
    });
    fetchForecast(cityName);
  } else {
  setState(() {
    hasData = false;
    errorMessage = "Konum verisi alınamadı";
    hourlyList = [];
    forecastList = [];
  });
}
  stillFetching = false;
  setState(() {
      isLoading = false;
    });
}
Future<void> saveSearch(String city) async {
  final prefs = await SharedPreferences.getInstance();
  
  if (searchHistory.contains(city)) {
    searchHistory.remove(city);
  }
  
  searchHistory.insert(0, city);
  
  if (searchHistory.length > 10) {
    searchHistory = searchHistory.sublist(0, 10);
  }
  
  await prefs.setStringList('history', searchHistory);
  setState(() {});
}
Future<void> clearHistory() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    searchHistory = [];
  });
  await prefs.setStringList('history', searchHistory);
}
Future<void> toggleFavorite(String city) async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    if (favorites.contains(city)) {
      favorites.remove(city);
    } else {
      favorites.add(city);
    }
  });
  await prefs.setStringList('favorites', favorites);
}
Future<void> loadHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList('history');
  final savedFavorites = prefs.getStringList('favorites');
  setState(() {
    if (saved != null) {
      searchHistory = saved;
    }
    if (savedFavorites != null) {
      favorites = savedFavorites;
    }
  });
}
@override
Widget build(BuildContext context) {
  bool isDark = themeNotifier.value == ThemeMode.dark;
  return GestureDetector(
    onTap: () {
      setState(() {
        showSuggestions = false;
      });
      cityFocusNode.unfocus();
    },
    child: SingleChildScrollView(
      child: Padding(
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Column(

    children: [
      Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(hasData ? getWeatherIcon(iconCode) : Icons.wb_sunny, color: Colors.orange, size: 28),
    SizedBox(width: 8),
    Text(
      "Hava Durumu",
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
  ],
),
SizedBox(height: 16),
      Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    IconButton(
      icon: Icon(
        themeNotifier.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
      ),
      onPressed: () {
        setState(() {
          themeNotifier.value =
              themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        });
      },
    ),
  ],
),
      TextField(
  controller: cityController,
  focusNode: cityFocusNode,
  onTap: () {
    setState(() {
      showSuggestions = true;
    });
  },
  decoration: InputDecoration(
    labelText: "Şehir adı girin",
    prefixIcon: Icon(Icons.search),
    filled: true,
fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
  ),
  onSubmitted: (value) {
  setState(() {
    showSuggestions = false;
  });
  fetchWeather(value);
  cityController.clear();
},
),
if (showSuggestions && searchHistory.isNotEmpty)
  Container(
  margin: EdgeInsets.only(top: 4),
  decoration: BoxDecoration(
    color: isDark ? Colors.grey[800] : Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Son Aramalar", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
              TextButton(
                onPressed: () {
                  clearHistory();
                },
                child: Text("Temizle", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        ...searchHistory.map((city) => ListTile(
  dense: true,
  leading: Icon(Icons.history, size: 20),
  title: Text(city),
  trailing: IconButton(
  focusNode: FocusNode(canRequestFocus: false),
  icon: Icon(
    favorites.contains(city) ? Icons.star : Icons.star_border,
    color: Colors.amber,
  ),
  onPressed: () {
    toggleFavorite(city);
  },
),
  onTap: () {
  cityController.text = city;
  cityFocusNode.unfocus();
  setState(() {
    showSuggestions = false;
  });
  fetchWeather(city);
},
)),
      ],
    ),
  ),
      SizedBox(height: 16),
      
      ElevatedButton.icon(
  onPressed: () {
    String city = cityController.text;
    setState(() {
      showSuggestions = false;
    });
    fetchWeather(city);
    cityController.clear();
  },
  icon: Icon(Icons.search),
  label: Text("Ara"),
  style: ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    padding: EdgeInsets.symmetric(vertical: 14),
    minimumSize: Size(double.infinity, 0),
  ),
),
SizedBox(height: 8),
ElevatedButton.icon(
  onPressed: () {
    fetchWeatherByLocation();
  },
  icon: Icon(Icons.my_location),
  label: Text("Konumumu Kullan"),
  style: ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    padding: EdgeInsets.symmetric(vertical: 14),
    minimumSize: Size(double.infinity, 0),
  ),
),
SizedBox(height: 16),
if (isLoading)
  Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Center(child: CircularProgressIndicator()),
  ),
if (hasData)
  Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: getWeatherGradient(iconCode),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(getWeatherIcon(iconCode), size: 48, color: Colors.white),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            "$cityName: ${temperature.round()}°C, $description",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        IconButton(
          icon: Icon(
            favorites.contains(cityName) ? Icons.star : Icons.star_border,
            color: Colors.white,
          ),
          onPressed: () {
            toggleFavorite(cityName);
          },
        ),
      ],
    ),
  ),
  if (hasData)
  Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Icon(Icons.water_drop, size: 20, color: Colors.blue),
            Text("$humidity%", style: TextStyle(fontSize: 14)),
            Text("Nem", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        Column(
          children: [
            Icon(Icons.air, size: 20, color: Colors.blueGrey),
            Text("${windSpeed.round()} m/s", style: TextStyle(fontSize: 14)),
            Text("Rüzgar", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        Column(
          children: [
            Icon(Icons.thermostat, size: 20, color: Colors.orange),
            Text("${feelsLike.round()}°C", style: TextStyle(fontSize: 14)),
            Text("Hissedilen", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    ),
  ),
  SizedBox(height: 16),
  if (hourlyList.isNotEmpty)
  SizedBox(
    height: 100,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: hourlyList.map((entry) {
  final hour = getHourText(entry['dt_txt']);
  final temp = entry['main']['temp'].round();
  final hourIcon = entry['weather'][0]['icon'];
  return Container(
    width: 70,
    margin: EdgeInsets.only(right: 8),
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
  color: Colors.blue[300],
  borderRadius: BorderRadius.circular(8),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 6,
      offset: Offset(0, 3),
    ),
  ],
),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(hour, style: TextStyle(fontSize: 12, color: Colors.white)),
Icon(getWeatherIcon(hourIcon), size: 20, color: Colors.white),
Text("$temp°C", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    ),
  );
}).toList(),
    ),
  ),
  SizedBox(height: 16),
  if (forecastList.isNotEmpty)
  SizedBox(
    height: 120,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: forecastList.asMap().entries.map((item) {
  final index = item.key;
  final entry = item.value;
  final date = index == 0 ? "Yarın" : getDayName(entry['dt_txt']);
  final temp = entry['main']['temp'].round();
  final dayIcon = entry['weather'][0]['icon'];
  return Container(
    width: 90,
    margin: EdgeInsets.only(right: 8),
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.blue[300],
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(date, style: TextStyle(fontSize: 12, color: Colors.white)),
        Icon(getWeatherIcon(dayIcon), size: 20, color: Colors.white),
        Text("$temp°C", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    ),
  );
}).toList(),
    ),
  ),
  if (errorMessage.isNotEmpty)
  Text(errorMessage, style: TextStyle(color: Colors.red)),
SizedBox(height: 16),
if (favorites.isNotEmpty)
  Text("Favoriler", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
...favorites.map((city) => ListTile(
  title: Text(city),
  leading: IconButton(
    icon: Icon(Icons.star, color: Colors.amber),
    onPressed: () {
      toggleFavorite(city);
    },
  ),
  onTap: () {
  fetchWeather(city, addToHistory: false);
},
)),
  
      ],
    ),
  ),
  ),
  );
}
}
