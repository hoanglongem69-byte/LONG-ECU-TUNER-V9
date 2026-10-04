import Foundation
import Combine

final class TunerViewModel: ObservableObject {
    @Published var engine = EngineData()
    @Published var mode: TunerMode = .simulation
    @Published var targetAFR: Double = 13.2
    @Published var fuelCorrection: Double = 0
    @Published var maxRPM: Int = 15000
    @Published var status = "SIMULATION"

    @Published var fuelMap: [[Double]]
    @Published var ignitionMap: [[Double]]

    let bluetooth = BluetoothManager()
    private var timer: Timer?

    init() {
        let rows = MapStore.rpm.count
        let cols = MapStore.tps.count
        fuelMap = Array(repeating: Array(repeating: 0.0, count: cols), count: rows)
        ignitionMap = Array(repeating: Array(repeating: 0.0, count: cols), count: rows)

        // Conservative starter values only; verify on a dyno/wideband before engine use.
        for r in 0..<rows {
            for c in 0..<cols {
                fuelMap[r][c] = 0
                ignitionMap[r][c] = 10
            }
        }
        startSimulation()
    }

    func startSimulation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard self.mode == .simulation else { return }
            self.engine.rpm += 250
            if self.engine.rpm > self.maxRPM { self.engine.rpm = 1000 }
            self.engine.tps = Double((self.engine.rpm / 250) % 101)
            self.engine.afr = 14.7 - self.engine.tps * 0.015
            self.engine.coolant = 70 + Double(self.engine.rpm) / 1500
            self.engine.voltage = 13.8
        }
    }

    func setFuel(row: Int, col: Int, value: Double) {
        fuelMap[row][col] = min(max(value, -50), 50)
    }

    func setIgnition(row: Int, col: Int, value: Double) {
        ignitionMap[row][col] = min(max(value, -10), 50)
    }

    // Closed-loop correction based on measured AFR.
    // Positive result means adding fuel; negative means removing fuel.
    func calculateAutoTune() {
        guard engine.afr > 5, targetAFR > 5 else { return }
        let correction = ((engine.afr / targetAFR) - 1.0) * 100.0
        fuelCorrection = min(max(correction, -30), 30)
        status = String(format: "AUTO TUNE: %+.1f%%", fuelCorrection)
    }

    func applyAutoTuneToCurrentCell() {
        let r = nearestRPMIndex(engine.rpm)
        let c = nearestTPSIndex(engine.tps)
        fuelMap[r][c] = min(max(fuelMap[r][c] + fuelCorrection, -50), 50)
        sendCurrentCell()
    }

    func sendCurrentCell() {
        let r = nearestRPMIndex(engine.rpm)
        let c = nearestTPSIndex(engine.tps)
        let rpm = MapStore.rpm[r]
        let tps = MapStore.tps[c]
        let fuel = fuelMap[r][c]
        let ign = ignitionMap[r][c]
        let packet = String(format: "MAP,%d,%d,%.2f,%.2f", rpm, tps, fuel, ign)
        bluetooth.send(packet)
    }

    func sendWholeMap() {
        guard mode == .bluetooth, bluetooth.isConnected else {
            status = "Chưa kết nối ESP32"
            return
        }
        for r in 0..<fuelMap.count {
            for c in 0..<fuelMap[r].count {
                let packet = String(format: "CELL,%d,%d,%.2f,%.2f",
                                    MapStore.rpm[r], MapStore.tps[c],
                                    fuelMap[r][c], ignitionMap[r][c])
                bluetooth.send(packet)
            }
        }
        status = "Đã gửi map"
    }

    private func nearestRPMIndex(_ rpm: Int) -> Int {
        MapStore.rpm.indices.min(by: { abs(MapStore.rpm[$0] - rpm) < abs(MapStore.rpm[$1] - rpm) }) ?? 0
    }

    private func nearestTPSIndex(_ tps: Double) -> Int {
        MapStore.tps.indices.min(by: { abs(Double(MapStore.tps[$0]) - tps) < abs(Double(MapStore.tps[$1]) - tps) }) ?? 0
    }
}
