#include <Wire.h>
#include <Adafruit_VL53L0X.h>
#include "DHT.h"

// --- DEFINICIÓN DE PINES SEGÚN LA TABLA ---
#define SDA_PIN 21        // ToF SDA
#define SCL_PIN 22        // ToF SCL
#define DHT_PIN 13        // DHT11 DATA
#define MIC_PIN 34        // MAX4466 OUT
#define LDR_PIN 35        // LDR Divisor B

#define DHTTYPE DHT11     // Modelo exacto del sensor de temperatura

// Instancias de los sensores
Adafruit_VL53L0X lox = Adafruit_VL53L0X();
DHT dht(DHT_PIN, DHTTYPE);

void setup() {
  Serial.begin(115200);
  
  // Esperar a que inicie el Serial Monitor
  while (!Serial) { delay(1); }
  
  Serial.println("\n--- INICIANDO TEST DE HARDWARE ESP32 ---");

  // 1. Iniciar I2C para el sensor de distancia
  Wire.begin(SDA_PIN, SCL_PIN);
  
  // --- INICIO ESCÁNER I2C ---
  Serial.println(F("Escaneando bus I2C buscando el ToF..."));
  byte error, address;
  int nDevices = 0;
  for(address = 1; address < 127; address++ ) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();
    if (error == 0) {
      Serial.print(F("¡Dispositivo I2C encontrado en la dirección 0x"));
      if (address<16) Serial.print("0");
      Serial.print(address,HEX);
      Serial.println(F(" !"));
      nDevices++;
    } else if (error==4) {
      Serial.print(F("Error desconocido en la dirección 0x"));
      if (address<16) Serial.print("0");
      Serial.println(address,HEX);
    }    
  }
  if (nDevices == 0) {
    Serial.println(F("❌ ERROR CRÍTICO: No se encontró NINGÚN dispositivo I2C."));
    Serial.println(F("   -> Posibles causas: Soldadura fría, cables rotos, o pines equivocados."));
  } else {
    Serial.println(F("✅ Escaneo I2C completado."));
  }
  // --- FIN ESCÁNER I2C ---

  if (!lox.begin()) {
    Serial.println(F("ERROR: El bus I2C funciona pero la librería no detectó el VL53L0X."));
  } else {
    Serial.println(F("OK: Sensor VL53L0X iniciado."));
  }

  // 2. Iniciar DHT11
  dht.begin();
  Serial.println(F("OK: Sensor DHT11 iniciado."));

  // 3. Configurar resolución del ADC del ESP32 (12 bits: 0-4095)
  analogReadResolution(12);
  
  Serial.println("\n--- SISTEMA LISTO. LEYENDO DATOS... ---\n");
}

void loop() {
  // --- LECTURA ANALÓGICA (Luz y Ruido) ---
  int ldrValue = analogRead(LDR_PIN);
  int micValue = analogRead(MIC_PIN);

  // --- LECTURA DHT11 (Temperatura y Humedad) ---
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  // --- LECTURA VL53L0X (Distancia) ---
  VL53L0X_RangingMeasurementData_t measure;
  lox.rangingTest(&measure, false); // false = sin debug

  // --- IMPRIMIR RESULTADOS ---
  Serial.print("Luz (LDR): "); Serial.print(ldrValue);
  Serial.print("\t| Ruido (Mic): "); Serial.print(micValue);
  
  // Validar si el DHT11 falló
  if (isnan(h) || isnan(t)) {
    Serial.print("\t| DHT: ERROR");
  } else {
    Serial.print("\t| Temp: "); Serial.print(t); Serial.print("C Hum: "); Serial.print(h); Serial.print("%");
  }

  // Validar si el ToF detectó algo
  if (measure.RangeStatus != 4) {  // 4 = Out of range
    Serial.print("\t| Distancia: "); Serial.print(measure.RangeMilliMeter); Serial.println(" mm");
  } else {
    Serial.println("\t| Distancia: Fuera de rango");
  }

  delay(2000); // Leer cada 2 segundos para no saturar el DHT11
}
