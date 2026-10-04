import Foundation

struct EngineData {
    var rpm: Int = 1000
    var tps: Double = 0
    var afr: Double = 14.7
    var coolant: Double = 25
    var voltage: Double = 12.6
}

enum TunerMode: String, CaseIterable {
    case simulation = "SIM"
    case bluetooth = "BLE"
}

struct MapStore {
    static let rpm = Array(stride(from: 500, through: 15000, by: 500))
    static let tps = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
}
