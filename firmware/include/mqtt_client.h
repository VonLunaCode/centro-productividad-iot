#ifndef MQTT_CLIENT_H
#define MQTT_CLIENT_H

#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include "config.h"

WiFiClientSecure espClient;
PubSubClient client(espClient);

void mqtt_callback(char* topic, byte* payload, unsigned int length) {
    Serial.print("MQTT: Mensaje recibido [");
    Serial.print(topic);
    Serial.print("] ");
    
    String message = "";
    for (int i = 0; i < length; i++) {
        message += (char)payload[i];
    }
    Serial.println(message);

    // Trigger calibration if topic matches
    if (String(topic) == TOPIC_CALIBRATE) {
        // Logic will be handled by calibration module
    }
}

void mqtt_init() {
    espClient.setInsecure(); // Skip certificate validation for simplicity
    client.setServer(MQTT_HOST, MQTT_PORT);
    client.setCallback(mqtt_callback);
}

void mqtt_reconnect() {
    while (!client.connected()) {
        Serial.print("MQTT: Intentando conexion...");
        
        // Connect with Last Will and Testament
        if (client.connect(DEVICE_ID, MQTT_USER, MQTT_PASS, TOPIC_STATUS, 1, true, "offline")) {
            Serial.println("Conectado!");
            client.publish(TOPIC_STATUS, "online", true);
            client.subscribe(TOPIC_CALIBRATE);
        } else {
            Serial.print("Fallo, rc=");
            Serial.print(client.state());
            Serial.println(" reintentando en 5s");
            delay(5000);
        }
    }
}

void mqtt_loop() {
    if (!client.connected()) {
        mqtt_reconnect();
    }
    client.loop();
}

bool mqtt_publish(const char* payload) {
    if (client.connected()) {
        return client.publish(TOPIC_SENSORS, payload);
    }
    return false;
}

#endif // MQTT_CLIENT_H
