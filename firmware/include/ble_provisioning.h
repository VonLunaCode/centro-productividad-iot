#ifndef BLE_PROVISIONING_H
#define BLE_PROVISIONING_H

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "config.h"
#include "wifi_manager.h"

static BLEServer* bleServer = nullptr;
static BLECharacteristic* bleStatusChar = nullptr;
static bool bleClientConnected = false;
static bool bleProvisioningDone = false;

static char pendingSsid[64] = "";
static char pendingPass[64] = "";

class BleServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* server) override {
        bleClientConnected = true;
        Serial.println("BLE: Cliente conectado");
    }
    void onDisconnect(BLEServer* server) override {
        bleClientConnected = false;
        Serial.println("BLE: Cliente desconectado");
        server->startAdvertising();
    }
};

class SsidWriteCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* c) override {
        strncpy(pendingSsid, c->getValue().c_str(), sizeof(pendingSsid) - 1);
        Serial.printf("BLE: SSID recibido -> %s\n", pendingSsid);
    }
};

class PassWriteCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* c) override {
        strncpy(pendingPass, c->getValue().c_str(), sizeof(pendingPass) - 1);
        Serial.println("BLE: Password recibida");

        // Intentar conexión WiFi con las credenciales recibidas
        bleStatusChar->setValue("connecting");
        bleStatusChar->notify();

        WiFi.mode(WIFI_STA);
        WiFi.begin(pendingSsid, pendingPass);

        int counter = 0;
        while (WiFi.status() != WL_CONNECTED && counter < 20) {
            delay(500);
            counter++;
        }

        if (WiFi.status() == WL_CONNECTED) {
            wifi_save_credentials(pendingSsid, pendingPass);
            bleStatusChar->setValue("ok");
            bleStatusChar->notify();
            Serial.println("BLE: Credenciales guardadas. Reiniciando...");
            bleProvisioningDone = true;
        } else {
            bleStatusChar->setValue("error");
            bleStatusChar->notify();
            Serial.println("BLE: No se pudo conectar con las credenciales recibidas.");
            WiFi.disconnect();
        }
    }
};

void ble_provisioning_start() {
    Serial.println("BLE: Iniciando modo provisioning...");

    BLEDevice::init(BLE_DEVICE_NAME);
    bleServer = BLEDevice::createServer();
    bleServer->setCallbacks(new BleServerCallbacks());

    BLEService* service = bleServer->createService(BLE_SERVICE_UUID);

    BLECharacteristic* ssidChar = service->createCharacteristic(
        BLE_CHAR_SSID_UUID, BLECharacteristic::PROPERTY_WRITE);
    ssidChar->setCallbacks(new SsidWriteCallbacks());

    BLECharacteristic* passChar = service->createCharacteristic(
        BLE_CHAR_PASS_UUID, BLECharacteristic::PROPERTY_WRITE);
    passChar->setCallbacks(new PassWriteCallbacks());

    bleStatusChar = service->createCharacteristic(
        BLE_CHAR_STATUS_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
    bleStatusChar->addDescriptor(new BLE2902());
    bleStatusChar->setValue("waiting");

    service->start();
    bleServer->getAdvertising()->start();

    Serial.printf("BLE: Advertising como '%s'\n", BLE_DEVICE_NAME);
}

// Returns true when credentials were saved and device should restart
bool ble_provisioning_loop() {
    if (bleProvisioningDone) {
        delay(500); // Let BLE notify flush
        return true;
    }
    return false;
}

#endif // BLE_PROVISIONING_H
