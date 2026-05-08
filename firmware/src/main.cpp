#include <Arduino.h>
#include "config.h"
#include "wifi_manager.h"
#include "mqtt_client.h"
#include "sensors.h"
#include "calibration.h"

unsigned long lastSensorPublish = 0;

// Override the weak mqtt_callback if needed or handle logic here
// For simplicity in this structure, we'll use a wrapper
void handle_mqtt_message(char* topic, byte* payload, unsigned int length) {
    String msg = "";
    for (int i = 0; i < length; i++) msg += (char)payload[i];
    
    if (String(topic) == TOPIC_CALIBRATE) {
        if (msg.indexOf("start") >= 0) {
            calibration_start();
        } else if (msg.indexOf("threshold") >= 0) {
            // Simple parsing for threshold value
            int idx = msg.indexOf(":");
            if (idx > 0) {
                int t = msg.substring(idx + 1).toInt();
                calibration_set_threshold(t);
            }
        }
    }
}

void setup() {
    Serial.begin(115200);
    delay(1000);
    
    sensors_init();
    wifi_init();
    mqtt_init();
    client.setCallback(handle_mqtt_message);
    
    Serial.println("\n--- SISTEMA LISTO ---");
}

void loop() {
    wifi_loop();
    
    if (wifi_is_connected()) {
        mqtt_loop();
        calibration_loop();
        
        unsigned long now = millis();
        if (now - lastSensorPublish > SENSOR_INTERVAL) {
            unsigned long ts = get_current_ts();
            
            // Posture alert check if threshold is set
            bool posture_alert = false;
            if (get_threshold() > 0) {
                // Read ToF for quick check
                VL53L0X_RangingMeasurementData_t measure;
                lox.rangingTest(&measure, false);
                if (measure.RangeStatus != 4 && measure.RangeMilliMeter < get_threshold()) {
                    posture_alert = true;
                }
            }

            char buffer[512];
            if (sensors_to_json(buffer, sizeof(buffer), ts, posture_alert, false)) {
                mqtt_publish(buffer);
                Serial.print("MQTT: Publicado -> ");
                Serial.println(buffer);
            }
            
            lastSensorPublish = now;
        }
    }
}
