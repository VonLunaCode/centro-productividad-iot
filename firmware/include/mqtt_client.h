#ifndef MQTT_CLIENT_H
#define MQTT_CLIENT_H

#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "config.h"

WiFiClientSecure espClient;
PubSubClient mqttClient(espClient);

// Controlled by MQTT commands from backend
bool capturing = false;

void mqtt_callback(char* topic, byte* payload, unsigned int length) {
    if (String(topic) != TOPIC_CMD) return;

    StaticJsonDocument<64> doc;
    DeserializationError err = deserializeJson(doc, payload, length);
    if (err) {
        Serial.printf("MQTT CMD: JSON invalido (%s)\n", err.c_str());
        return;
    }

    const char* action = doc["action"] | "";
    if (strcmp(action, "start") == 0) {
        capturing = true;
        Serial.println("MQTT CMD: Captura INICIADA");
    } else if (strcmp(action, "stop") == 0) {
        capturing = false;
        Serial.println("MQTT CMD: Captura DETENIDA");
    }
}

void mqtt_init() {
    espClient.setInsecure();
    mqttClient.setServer(MQTT_HOST, MQTT_PORT);
    mqttClient.setCallback(mqtt_callback);
}

void mqtt_reconnect() {
    while (!mqttClient.connected()) {
        Serial.print("MQTT: Conectando...");
        if (mqttClient.connect(DEVICE_ID, MQTT_USER, MQTT_PASS, TOPIC_STATUS, 1, true, "offline")) {
            Serial.println(" OK");
            mqttClient.publish(TOPIC_STATUS, "online", true);
            mqttClient.subscribe(TOPIC_CMD);
        } else {
            Serial.printf(" Fallo rc=%d, reintentando en 5s\n", mqttClient.state());
            delay(5000);
        }
    }
}

void mqtt_loop() {
    if (!mqttClient.connected()) mqtt_reconnect();
    mqttClient.loop();
}

bool mqtt_publish(const char* payload) {
    if (mqttClient.connected()) {
        return mqttClient.publish(TOPIC_SENSORS, payload);
    }
    return false;
}

#endif // MQTT_CLIENT_H
