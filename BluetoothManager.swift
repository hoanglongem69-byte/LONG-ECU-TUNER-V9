import Foundation
import CoreBluetooth

final class BluetoothManager: NSObject, ObservableObject {
    @Published var isPoweredOn = false
    @Published var isConnected = false
    @Published var deviceName = "Chưa kết nối"

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?

    // Replace with the UUIDs used by your ESP32 firmware.
    let serviceUUID = CBUUID(string: "FFE0")
    let characteristicUUID = CBUUID(string: "FFE1")

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func scan() {
        guard isPoweredOn else { return }
        central.scanForPeripherals(withServices: nil, options: nil)
    }

    func disconnect() {
        if let p = peripheral { central.cancelPeripheralConnection(p) }
    }

    func send(_ text: String) {
        guard let p = peripheral,
              let characteristic = p.services?.flatMap({ $0.characteristics ?? [] })
                .first(where: { $0.uuid == characteristicUUID }),
              let data = (text + "\n").data(using: .utf8) else { return }
        p.writeValue(data, for: characteristic, type: .withResponse)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isPoweredOn = central.state == .poweredOn
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        self.peripheral = peripheral
        deviceName = peripheral.name ?? "ESP32"
        central.connect(peripheral, options: nil)
        central.stopScan()
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        peripheral.services?.forEach {
            peripheral.discoverCharacteristics([characteristicUUID], for: $0)
        }
    }
}
