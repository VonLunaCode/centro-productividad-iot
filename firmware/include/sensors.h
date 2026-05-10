#ifndef SENSORS_H
#define SENSORS_H

#include <Wire.h>
#include <Adafruit_VL53L0X.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include "config.h"

Adafruit_VL53L0X lox = Adafruit_VL53L0X();
DHT dht(PIN_DHT, DHT11);

float lastTemp = 0;
float lastHum = 0;
unsigned long lastDHTRead = 0;

void sensors_init() {
    Serial.println("Sensores: Inicializando...");
    Wire.begin(PIN_SDA, PIN_SCL, 100000);

    if (!lox.begin()) {
        Serial.println("ToF: Error al inicializar VL53L0X");
    }

    dht.begin();
    pinMode(PIN_LDR, INPUT);
    pinMode(PIN_MIC, INPUT);
}

int get_noise_peak() {
    int signalMax = 0;
    int signalMin = 4095;
    unsigned long start = millis();
    while (millis() - start < 50) {
        int s = analogRead(PIN_MIC);
        if (s > signalMax) signalMax = s;
        if (s < signalMin) signalMin = s;
    }
    return signalMax - signalMin;
}

// Field names match what the backend mqtt_subscriber.py expects
bool sensors_to_json(char* buffer, size_t size, unsigned long ts) {
    StaticJsonDocument<256> doc;

    doc["device_id"] = DEVICE_ID;
    doc["ts"] = ts;

    JsonObject sensors = doc.createNestedObject("sensors");

    VL53L0X_RangingMeasurementData_t measure;
    lox.rangingTest(&measure, false);
    sensors["distance_mm"] = (measure.RangeStatus != 4) ? (float)measure.RangeMilliMeter : -1.0f;

    if (millis() - lastDHTRead > 2000) {
        float t = dht.readTemperature();
        float h = dht.readHumidity();
        if (!isnan(t) && !isnan(h)) {
            lastTemp = t;
            lastHum = h;
            lastDHTRead = millis();
        }
    }
    sensors["temperature"] = lastTemp;
    sensors["humidity"] = lastHum;

    // LDR: map 0-4095 ADC to approximate lux (linear approximation for LDR divider)
    int ldrRaw = analogRead(PIN_LDR);
    sensors["lux"] = map(ldrRaw, 0, 4095, 0, 1000);

    sensors["noise_peak"] = get_noise_peak();

    return serializeJson(doc, buffer, size) > 0;
}

#endif // SENSORS_H
