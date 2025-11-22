#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <DHT.h>

// ========== CONFIGURATION ==========
#define WIFI_SSID "Wokwi-GUEST"
#define WIFI_PASSWORD ""

// 🔥 Your Firebase URL
#define FIREBASE_HOST "https://smart-hydroponic-8529f-default-rtdb.europe-west1.firebasedatabase.app"

// ========== PIN DEFINITIONS ==========
#define DHTPIN 4           // DHT22 Temperature sensor
#define DHTTYPE DHT22
#define WATER_LEVEL_PIN 34 // Potentiometer 1
#define PH_LEVEL_PIN 35    // Potentiometer 2
#define TDS_PIN 32         // Potentiometer 3
#define LIGHT_SENSOR_PIN 33 // Photoresistor

DHT dht(DHTPIN, DHTTYPE);

// Timing
unsigned long lastUpdate = 0;
const long updateInterval = 2000; // Update every 2 seconds

void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n\n");
  Serial.println("╔════════════════════════════════════╗");
  Serial.println("║    🌱 AquaGrow Sensor Simulator    ║");
  Serial.println("╚════════════════════════════════════╝");
  
  // Initialize sensors
  dht.begin();
  pinMode(WATER_LEVEL_PIN, INPUT);
  pinMode(PH_LEVEL_PIN, INPUT);
  pinMode(TDS_PIN, INPUT);
  pinMode(LIGHT_SENSOR_PIN, INPUT);
  
  Serial.println("✓ 5 Sensors initialized:");
  Serial.println("  • DHT22 (Temperature)");
  Serial.println("  • Potentiometer 1 (Water Level)");
  Serial.println("  • Potentiometer 2 (pH Level)");
  Serial.println("  • Potentiometer 3 (TDS/EC)");
  Serial.println("  • Photoresistor (Light)");
  
  // Connect to WiFi
  Serial.println("\n📡 Connecting to WiFi...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✓ WiFi Connected!");
    Serial.print("  IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("  Firebase: ");
    Serial.println(FIREBASE_HOST);
  } else {
    Serial.println("\n❌ WiFi Connection Failed!");
  }
  
  Serial.println("════════════════════════════════════\n");
}

void loop() {
  unsigned long currentMillis = millis();
  
  if (currentMillis - lastUpdate >= updateInterval) {
    lastUpdate = currentMillis;
    
    // Check WiFi connection
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("❌ WiFi disconnected! Reconnecting...");
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
      delay(1000);
      return;
    }
    
    Serial.println("\n╔════════════════════════════════════╗");
    Serial.println("║       📊 Reading Sensors...        ║");
    Serial.println("╚════════════════════════════════════╝");
    
    // ========== READ ALL SENSORS ==========
    
    // 1. Temperature (from DHT22)
    float temperature = dht.readTemperature();
    if (isnan(temperature)) {
      temperature = 25.0;
      Serial.println("⚠️  DHT22 read failed, using default");
    }
    
    // 2. Water Level (from Potentiometer 1: 0-100%)
    int waterLevelRaw = analogRead(WATER_LEVEL_PIN);
    int waterLevel = map(waterLevelRaw, 0, 4095, 0, 100);
    
    // 3. pH Level (from Potentiometer 2: 4.0-8.0)
    int phRaw = analogRead(PH_LEVEL_PIN);
    float phValue = map(phRaw, 0, 4095, 40, 80) / 10.0;
    
    // 4. TDS/EC (from Potentiometer 3: 500-2000 ppm)
    int tdsRaw = analogRead(TDS_PIN);
    int tdsValue = map(tdsRaw, 0, 4095, 500, 2000);
    
    // 5. Light Level (from Photoresistor: 0-1000 lux)
    int lightRaw = analogRead(LIGHT_SENSOR_PIN);
    int lightLevel = map(lightRaw, 0, 4095, 0, 1000);
    
    // ========== DETERMINE STATUS ==========
    
    String tempStatus = (temperature >= 22 && temperature <= 28) ? "optimal" : "warning";
    String waterStatus = (waterLevel >= 40) ? "good" : "critical";
    String phStatus = (phValue >= 5.8 && phValue <= 6.8) ? "optimal" : "warning";
    String tdsStatus = (tdsValue >= 800 && tdsValue <= 1500) ? "good" : "warning";
    String lightStatus = (lightLevel >= 200 && lightLevel <= 800) ? "good" : "warning";
    
    // ========== PRINT TO SERIAL ==========
    
    Serial.printf("🌡️  Temperature: %.1f°C [%s]\n", temperature, tempStatus.c_str());
    Serial.printf("💧 Water Level: %d%% [%s]\n", waterLevel, waterStatus.c_str());
    Serial.printf("⚗️  pH Level: %.1f [%s]\n", phValue, phStatus.c_str());
    Serial.printf("⚡ TDS/EC: %d ppm [%s]\n", tdsValue, tdsStatus.c_str());
    Serial.printf("☀️  Light: %d lux [%s]\n", lightLevel, lightStatus.c_str());
    
    // ========== BATCH UPLOAD TO FIREBASE ==========
    
    Serial.println("\n📤 Uploading to Firebase (batch)...");
    
    if (uploadAllSensors(temperature, waterLevel, phValue, tdsValue, lightLevel,
                         tempStatus, waterStatus, phStatus, tdsStatus, lightStatus)) {
      Serial.println("✅ All sensors uploaded successfully!");
    } else {
      Serial.println("⚠️  Upload failed, will retry next cycle");
    }
    
    Serial.println("════════════════════════════════════\n");
  }
}

// ========== BATCH UPLOAD FUNCTION (OPTIMIZED) ==========
bool uploadAllSensors(float temp, int water, float ph, int tds, int light,
                      String tempStatus, String waterStatus, String phStatus, 
                      String tdsStatus, String lightStatus) {
  HTTPClient http;
  String url = String(FIREBASE_HOST) + "/sensors.json";
  
  // Create large JSON with all sensors
  StaticJsonDocument<1024> doc;
  unsigned long timestamp = millis();
  
  // Temperature
  doc["temperature"]["value"] = temp;
  doc["temperature"]["unit"] = "°C";
  doc["temperature"]["timestamp"] = timestamp;
  doc["temperature"]["status"] = tempStatus;
  doc["temperature"]["min"] = 22;
  doc["temperature"]["max"] = 28;
  
  // Water Level
  doc["waterLevel"]["value"] = water;
  doc["waterLevel"]["unit"] = "%";
  doc["waterLevel"]["timestamp"] = timestamp;
  doc["waterLevel"]["status"] = waterStatus;
  doc["waterLevel"]["min"] = 40;
  doc["waterLevel"]["max"] = 100;
  
  // pH Level
  doc["pH"]["value"] = ph;
  doc["pH"]["unit"] = "pH";
  doc["pH"]["timestamp"] = timestamp;
  doc["pH"]["status"] = phStatus;
  doc["pH"]["min"] = 5.8;
  doc["pH"]["max"] = 6.8;
  
  // TDS/EC
  doc["tds"]["value"] = tds;
  doc["tds"]["unit"] = "ppm";
  doc["tds"]["timestamp"] = timestamp;
  doc["tds"]["status"] = tdsStatus;
  doc["tds"]["min"] = 800;
  doc["tds"]["max"] = 1500;
  
  // Light
  doc["light"]["value"] = light;
  doc["light"]["unit"] = "lux";
  doc["light"]["timestamp"] = timestamp;
  doc["light"]["status"] = lightStatus;
  doc["light"]["min"] = 200;
  doc["light"]["max"] = 800;
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  // Send PUT request
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(5000); // 5 second timeout
  
  int httpResponseCode = http.PUT(jsonString);
  
  bool success = (httpResponseCode == 200);
  
  if (success) {
    Serial.printf("  ✓ HTTP Response: %d (OK)\n", httpResponseCode);
  } else {
    Serial.printf("  ✗ HTTP Error: %d\n", httpResponseCode);
  }
  
  http.end();
  return success;
}
