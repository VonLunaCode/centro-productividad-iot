#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <WiFi.h>
#include <Preferences.h>
#include <time.h>
#include "config.h"

static Preferences wifiPrefs;

void wifi_save_credentials(const char* ssid, const char* pass) {
    wifiPrefs.begin("wifi", false);
    wifiPrefs.putString("ssid", ssid);
    wifiPrefs.putString("pass", pass);
    wifiPrefs.end();
}

bool wifi_has_credentials() {
    wifiPrefs.begin("wifi", true);
    bool has = wifiPrefs.isKey("ssid");
    wifiPrefs.end();
    return has;
}

bool wifi_connect() {
    wifiPrefs.begin("wifi", true);
    String ssid = wifiPrefs.getString("ssid", "");
    String pass = wifiPrefs.getString("pass", "");
    wifiPrefs.end();

    if (ssid.isEmpty()) return false;

    Serial.printf("WiFi: Conectando a %s...\n", ssid.c_str());
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid.c_str(), pass.c_str());

    int counter = 0;
    while (WiFi.status() != WL_CONNECTED && counter < 40) {
        delay(500);
        Serial.print(".");
        counter++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.printf("\nWiFi Conectado! IP: %s\n", WiFi.localIP().toString().c_str());
        configTime(0, 0, "pool.ntp.org", "time.nist.gov");
        return true;
    }

    Serial.println("\nWiFi: No se pudo conectar.");
    return false;
}

unsigned long lastWifiRetry = 0;
unsigned long wifiRetryInterval = 5000;

void wifi_loop() {
    if (WiFi.status() != WL_CONNECTED) {
        unsigned long now = millis();
        if (now - lastWifiRetry > wifiRetryInterval) {
            Serial.println("WiFi: Reconectando...");
            wifi_connect();
            lastWifiRetry = now;
            wifiRetryInterval = min(wifiRetryInterval * 2, 30000UL);
        }
    } else {
        wifiRetryInterval = 5000;
    }
}

bool wifi_is_connected() {
    return WiFi.status() == WL_CONNECTED;
}

unsigned long get_current_ts() {
    time_t now;
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) return 0;
    time(&now);
    return (unsigned long)now;
}

#endif // WIFI_MANAGER_H
