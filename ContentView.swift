import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: TunerViewModel
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.67percent") }
            FuelMapView().tabItem { Label("Xăng", systemImage: "drop.fill") }
            IgnitionMapView().tabItem { Label("Lửa", systemImage: "bolt.fill") }
            AutoTuneView().tabItem { Label("Auto Tune", systemImage: "wand.and.stars") }
            SettingsView().tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
        }
        .tint(.orange)
    }
}

struct DashboardView: View {
    @EnvironmentObject var vm: TunerViewModel
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("LONG ECU TUNER V8")
                        .font(.largeTitle.bold())
                    Text(vm.status).font(.caption).foregroundStyle(.secondary)

                    HStack {
                        Metric(title: "RPM", value: "\(vm.engine.rpm)", unit: "rpm")
                        Metric(title: "AFR", value: String(format: "%.2f", vm.engine.afr), unit: "")
                    }
                    HStack {
                        Metric(title: "TPS", value: String(format: "%.0f", vm.engine.tps), unit: "%")
                        Metric(title: "Nhiệt", value: String(format: "%.1f", vm.engine.coolant), unit: "°C")
                    }
                    HStack {
                        Metric(title: "Điện áp", value: String(format: "%.2f", vm.engine.voltage), unit: "V")
                        Metric(title: "Giới hạn", value: "\(vm.maxRPM)", unit: "rpm")
                    }

                    Button(vm.bluetooth.isConnected ? "Đã kết nối ESP32" : "Quét ESP32 BLE") {
                        vm.bluetooth.scan()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct Metric: View {
    let title: String
    let value: String
    let unit: String
    var body: some View {
        VStack {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(size: 30, weight: .bold, design: .rounded))
            Text(unit).font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct FuelMapView: View {
    @EnvironmentObject var vm: TunerViewModel
    var body: some View {
        MapEditor(title: "FUEL MAP", suffix: "%", values: $vm.fuelMap,
                  min: -50, max: 50,
                  onChange: vm.setFuel)
    }
}

struct IgnitionMapView: View {
    @EnvironmentObject var vm: TunerViewModel
    var body: some View {
        MapEditor(title: "IGNITION MAP", suffix: "°", values: $vm.ignitionMap,
                  min: -10, max: 50,
                  onChange: vm.setIgnition)
    }
}

struct MapEditor: View {
    let title: String
    let suffix: String
    @Binding var values: [[Double]]
    let min: Double
    let max: Double
    let onChange: (Int, Int, Double) -> Void

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.title.bold()).padding()
                    HStack {
                        Text("RPM / TPS").frame(width: 100)
                        ForEach(MapStore.tps, id: \.self) { tps in
                            Text("\(tps)").frame(width: 70)
                        }
                    }
                    ForEach(values.indices, id: \.self) { r in
                        HStack {
                            Text("\(MapStore.rpm[r])").frame(width: 100)
                            ForEach(values[r].indices, id: \.self) { c in
                                TextField("", value: Binding(
                                    get: { values[r][c] },
                                    set: { newValue in onChange(r, c, newValue) }
                                ), format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 70, height: 42)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Map")
        }
    }
}

struct AutoTuneView: View {
    @EnvironmentObject var vm: TunerViewModel
    var body: some View {
        NavigationStack {
            Form {
                Section("AFR") {
                    HStack {
                        Text("AFR hiện tại")
                        Spacer()
                        Text(String(format: "%.2f", vm.engine.afr))
                    }
                    HStack {
                        Text("AFR mục tiêu")
                        Spacer()
                        TextField("", value: $vm.targetAFR, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Correction") {
                    Text(String(format: "%+.1f %%", vm.fuelCorrection))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Button("Tính Auto Tune") { vm.calculateAutoTune() }
                        .buttonStyle(.borderedProminent)
                    Button("Áp dụng vào ô RPM/TPS hiện tại") {
                        vm.applyAutoTuneToCurrentCell()
                    }
                }

                Section("Lưu ý") {
                    Text("Auto Tune này chỉ là thuật toán correction cơ bản. Khi chạy ECU thật cần wideband AFR, xác minh cảm biến và giới hạn correction trước khi ghi map.")
                }
            }
            .navigationTitle("AUTO TUNE")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var vm: TunerViewModel
    var body: some View {
        NavigationStack {
            Form {
                Section("Mode") {
                    Picker("Chế độ", selection: $vm.mode) {
                        ForEach(TunerMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("RPM") {
                    Stepper("Giới hạn: \(vm.maxRPM) RPM",
                            value: $vm.maxRPM,
                            in: 500...15000,
                            step: 500)
                }

                Section("ESP32 BLE") {
                    Text(vm.bluetooth.deviceName)
                    Button("Quét thiết bị") { vm.bluetooth.scan() }
                    Button("Gửi cell hiện tại") { vm.sendCurrentCell() }
                    Button("Gửi toàn bộ map") { vm.sendWholeMap() }
                        .foregroundStyle(.orange)
                }

                Section("Thông tin") {
                    Text("LONG ECU TUNER V8")
                    Text("RPM tối đa giao diện: 15.000")
                    Text("Fuel: ±50% • Ignition: -10° đến 50°")
                }
            }
            .navigationTitle("Cài đặt")
        }
    }
}
