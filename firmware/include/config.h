#ifndef CONFIG_H
#define CONFIG_H

// WiFi Configuration
// TODO: Replace with your actual WiFi credentials
#define WIFI_SSID "VonLuna5G"
#define WIFI_PASS "fxAsYYPHFNDReUU"

// MQTT Configuration (HiveMQ Cloud)
#define MQTT_HOST "2503ca92a57b47a2860cdc3c3b9477b2.s1.eu.hivemq.cloud"
#define MQTT_PORT 8883
#define MQTT_USER "esp32-client"
#define MQTT_PASS "Esp32-client"
#define DEVICE_ID "esp32-01"

// MQTT Topics
#define TOPIC_SENSORS   "centro-productividad/esp32-01/sensors"
#define TOPIC_CALIBRATE "centro-productividad/esp32-01/calibrate"
#define TOPIC_STATUS    "centro-productividad/esp32-01/status"

// Hardware Pins
#define PIN_DHT        13
#define PIN_LDR        35
#define PIN_MIC        34
#define PIN_SDA        21
#define PIN_SCL        22

// ToF Sensor (VL53L0X) usually uses default I2C pins, but we define them for clarity
// and custom Wire initialization if needed.

// Intervals (ms)
#define SENSOR_INTERVAL      2000
#define CALIBRATION_SAMPLES  10
#define CALIBRATION_TIMEOUT  10000
#define NTP_SYNC_INTERVAL    3600000 // 1 hour

#endif // CONFIG_H
