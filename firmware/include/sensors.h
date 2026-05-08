#ifndef SENSORS_H
#define SENSORS_H

#include <Wire.h>
#include <Adafruit_VL53L0X.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include "config.h"

Adafruit_VL53L0X lox = Adafruit_VL53L0X();
DHT dht(PIN_DHT, DHT11);

// Last readings for fallback
float lastTemp = 0;
float lastHum = 0;
unsigned long lastDHTRead = 0;

void sensors_init() {
    Serial.println("Sensores: Inicializando...");
    Wire.begin(PIN_SDA, PIN_SCL, 100000); // 100kHz for stability
    
    if (!lox.begin()) {
        Serial.println("ToF: Error al inicializar VL53L0X");
    }
    
    dht.begin();
    pinMode(PIN_LDR, INPUT);
    pinMode(PIN_MIC, INPUT);
}

int get_noise_peak() {
    unsigned long startMillis = millis();
    int peakToPeak = 0;
    int signalMax = 0;
    int signalMin = 4095;

    while (millis() - startMillis < 50) { // 50ms window
        int sample = analogRead(PIN_MIC);
        if (sample > signalMax) signalMax = sample;
        if (sample < signalMin) signalMin = sample;
    }
    peakToPeak = signalMax - signalMin;
    return peakToPeak;
}

bool sensors_to_json(char* buffer, size_t size, unsigned long ts, bool posture_alert, bool light_alert) {
    StaticJsonDocument<256> doc;
    
    doc["device_id"] = DEVICE_ID;
    doc["ts"] = ts;

    JsonObject sensors = doc.createNestedObject("sensors");
    
    // VL53L0X Distance
    VL53L0X_RangingMeasurementData_t measure;
    lox.rangingTest(&measure, false);
    if (measure.RangeStatus != 4) {
        sensors["distance_mm"] = measure.RangeMilliMeter;
    } else {
        sensors["distance_mm"] = -1; // Error status
    }

    // DHT11 with 2s guard
    if (millis() - lastDHTRead > 2000) {
        float t = dht.readTemperature();
        float h = dht.readHumidity();
        if (!isnan(t) && !isnan(h)) {
            lastTemp = t;
            lastHum = h;
            lastDHTRead = millis();
        }
    }
    sensors["temperature_c"] = lastTemp;
    sensors["humidity_pct"] = lastHum;

    // LDR and Mic
    sensors["light_raw"] = analogRead(PIN_LDR);
    sensors["noise_peak"] = get_noise_peak();

    JsonObject alerts = doc.createNestedObject("alerts");
    alerts["posture"] = posture_alert;
    alerts["low_light"] = light_alert;

    if (serializeJson(doc, buffer, size) == 0) {
        return false;
    }
    return true;
}

#endif // SENSORS_H
