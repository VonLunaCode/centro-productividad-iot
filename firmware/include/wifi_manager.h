#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <WiFi.h>
#include <time.h>
#include "config.h"

unsigned long lastWifiRetry = 0;
unsigned long wifiRetryInterval = 5000; // Start with 5s

void wifi_init() {
    Serial.println("\n--- WiFi: Iniciando ---");
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASS);

    int counter = 0;
    while (WiFi.status() != WL_CONNECTED && counter < 60) { // 30s timeout (500ms * 60)
        delay(500);
        Serial.print(".");
        counter++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi Conectado!");
        Serial.print("IP: ");
        Serial.println(WiFi.localIP());
        
        // Sync NTP
        configTime(0, 0, "pool.ntp.org", "time.nist.gov");
        Serial.println("NTP: Sincronizando...");
    } else {
        Serial.println("\nWiFi: Timeout en conexion inicial.");
    }
}

void wifi_loop() {
    if (WiFi.status() != WL_CONNECTED) {
        unsigned long now = millis();
        if (now - lastWifiRetry > wifiRetryInterval) {
            Serial.println("WiFi: Reconectando...");
            WiFi.disconnect();
            WiFi.begin(WIFI_SSID, WIFI_PASS);
            lastWifiRetry = now;
            
            // Exponential backoff
            wifiRetryInterval *= 2;
            if (wifiRetryInterval > 30000) wifiRetryInterval = 30000; // Cap at 30s
        }
    } else {
        wifiRetryInterval = 5000; // Reset interval on success
    }
}

bool wifi_is_connected() {
    return WiFi.status() == WL_CONNECTED;
}

unsigned long get_current_ts() {
    time_t now;
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        return 0;
    }
    time(&now);
    return (unsigned long)now;
}

#endif // WIFI_MANAGER_H
