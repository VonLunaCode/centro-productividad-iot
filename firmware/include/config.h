#ifndef CONFIG_H
#define CONFIG_H

// MQTT Configuration (HiveMQ Cloud)
#define MQTT_HOST "2503ca92a57b47a2860cdc3c3b9477b2.s1.eu.hivemq.cloud"
#define MQTT_PORT 8883
#define MQTT_USER "esp32-client"
#define MQTT_PASS "Esp32-client"
#define DEVICE_ID "esp32-01"

// MQTT Topics
#define TOPIC_SENSORS "centro-productividad/esp32-01/sensors"
#define TOPIC_CMD     "centro-productividad/esp32-01/cmd"
#define TOPIC_STATUS  "centro-productividad/esp32-01/status"

// BLE Provisioning UUIDs
#define BLE_DEVICE_NAME     "CentroProductividad"
#define BLE_SERVICE_UUID    "12345678-1234-1234-1234-123456789abc"
#define BLE_CHAR_SSID_UUID  "12345678-1234-1234-1234-123456789001"
#define BLE_CHAR_PASS_UUID  "12345678-1234-1234-1234-123456789002"
#define BLE_CHAR_STATUS_UUID "12345678-1234-1234-1234-123456789003"

// Hardware Pins
#define PIN_DHT 13
#define PIN_LDR 35
#define PIN_MIC 34  // KY-037 AO
#define PIN_SDA 21
#define PIN_SCL 22

// Intervals (ms)
#define SENSOR_INTERVAL   2000
#define NTP_SYNC_INTERVAL 3600000

#endif // CONFIG_H
