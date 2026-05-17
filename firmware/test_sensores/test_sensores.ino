// =====================================================
// TEST COMPLETO RAW - TODOS LOS SENSORES
// KY-037 (Pin 34), LDR (Pin 35), DHT11 (Pin 13)
// VL53L0X (SDA=21, SCL=22)
// Serial Monitor a 115200 - SIN WIFI NI MQTT
// =====================================================
#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_VL53L0X.h>
#include <DHT.h>

#define PIN_SDA  21
#define PIN_SCL  22
#define PIN_DHT  13
#define PIN_LDR  35
#define PIN_MIC  34  // KY-037 AO

Adafruit_VL53L0X lox = Adafruit_VL53L0X();
DHT dht(PIN_DHT, DHT11);

// 3 ventanas de 500ms, retorna la maxima amplitud
int sample_window(int ms) {
    int signalMax = 0;
    int signalMin = 4095;
    unsigned long start = millis();
    while (millis() - start < (unsigned long)ms) {
        int s = analogRead(PIN_MIC);
        if (s > signalMax) signalMax = s;
        if (s < signalMin) signalMin = s;
    }
    return signalMax - signalMin;
}

int get_noise_peak() {
    int a = sample_window(500);
    int b = sample_window(500);
    int c = sample_window(500);
    return max(a, max(b, c));
}

void setup() {
    Serial.begin(115200);
    delay(1000);
    Serial.println("\n========================================");
    Serial.println("  TEST COMPLETO RAW - TODOS LOS SENSORES");
    Serial.println("========================================\n");

    Wire.begin(PIN_SDA, PIN_SCL);

    Serial.print("[VL53L0X] Inicializando... ");
    if (!lox.begin()) {
        Serial.println("ERROR - revisar SDA(21) y SCL(22)");
    } else {
        Serial.println("OK");
    }

    dht.begin();
    Serial.println("[DHT11]   OK - Pin 13");

    pinMode(PIN_LDR, INPUT);
    Serial.println("[LDR]     OK - Pin 35");

    pinMode(PIN_MIC, INPUT);
    analogReadResolution(12);
    Serial.println("[KY-037]  OK - Pin 34 (AO)");

    Serial.println("\n--- INICIANDO LECTURAS CADA ~3 SEGUNDOS ---\n");
    delay(1000);
}

void loop() {
    Serial.println("==========================================");

    // --- VL53L0X ---
    VL53L0X_RangingMeasurementData_t measure;
    lox.rangingTest(&measure, false);
    if (measure.RangeStatus != 4) {
        Serial.printf("[DISTANCIA] %d mm  (rango ok)\n", measure.RangeMilliMeter);
    } else {
        Serial.println("[DISTANCIA] -1  (fuera de rango o error)");
    }

    // --- DHT11 ---
    float temp = dht.readTemperature();
    float hum  = dht.readHumidity();
    if (isnan(temp) || isnan(hum)) {
        Serial.println("[DHT11]     ERROR - no responde");
    } else {
        Serial.printf("[TEMP]      %.1f C\n", temp);
        Serial.printf("[HUMEDAD]   %.0f %%\n", hum);
    }

    // --- LDR ---
    int ldrRaw = analogRead(PIN_LDR);
    int lux    = map(ldrRaw, 0, 4095, 0, 1000);
    Serial.printf("[LUZ RAW]   %d  (0-4095)\n", ldrRaw);
    Serial.printf("[LUZ LUX]   %d  (0-1000 aprox)\n", lux);

    // --- KY-037 ---
    Serial.println("[MIC]       Muestreando 1.5s...");
    int noiseRaw = get_noise_peak();
    int micSnap  = analogRead(PIN_MIC);
    Serial.printf("[RUIDO P2P] %d  (max de 3 ventanas)\n", noiseRaw);
    Serial.printf("[MIC SNAP]  %d  (muestra unica)\n", micSnap);

    Serial.println();
    delay(500);
}
