#ifndef CALIBRATION_H
#define CALIBRATION_H

#include "sensors.h"
#include "mqtt_client.h"

enum CalibState { IDLE, SAMPLING, DONE };
CalibState currentCalibState = IDLE;

int samplesCount = 0;
long samplesSum = 0;
int threshold_mm = 0; // Current threshold for alerts

void calibration_start() {
    Serial.println("Calibracion: Iniciando muestreo...");
    currentCalibState = SAMPLING;
    samplesCount = 0;
    samplesSum = 0;
}

void calibration_loop() {
    if (currentCalibState == SAMPLING) {
        VL53L0X_RangingMeasurementData_t measure;
        lox.rangingTest(&measure, false);
        
        if (measure.RangeStatus != 4) {
            samplesSum += measure.RangeMilliMeter;
            samplesCount++;
        }

        if (samplesCount >= CALIBRATION_SAMPLES) {
            int baseline = samplesSum / CALIBRATION_SAMPLES;
            Serial.print("Calibracion: Baseline calculada: ");
            Serial.println(baseline);
            
            // Send back to server
            StaticJsonDocument<128> doc;
            doc["device_id"] = DEVICE_ID;
            doc["calibrating"] = true;
            doc["baseline_mm"] = baseline;
            
            char buffer[128];
            serializeJson(doc, buffer);
            mqtt_publish(buffer);
            
            currentCalibState = IDLE;
        }
    }
}

void calibration_set_threshold(int mm) {
    threshold_mm = mm;
    Serial.print("Calibracion: Nuevo threshold seteado: ");
    Serial.println(threshold_mm);
}

int get_threshold() {
    return threshold_mm;
}

#endif // CALIBRATION_H
