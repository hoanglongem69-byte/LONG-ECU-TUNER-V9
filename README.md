# LONG ECU TUNER V8

SwiftUI iPhone app prototype for:
- Fuel Map
- Ignition Map
- Auto Tune AFR correction
- RPM axis 500–15,000
- ESP32 Bluetooth LE transport layer
- Simulation mode

## Build
1. Mở Xcode trên Mac.
2. File > New > Project > iOS App.
3. Chọn SwiftUI / Swift.
4. Thay các file Swift mặc định bằng các file trong thư mục này.
5. Target iOS 17+.
6. Thêm Bluetooth permission vào Info.plist:
   Privacy - Bluetooth Always Usage Description
7. Build lên iPhone.

## ESP32 protocol
BLE characteristic gửi chuỗi UTF-8, kết thúc bằng newline.

Ví dụ:
MAP,5000,40,2.50,28.00
CELL,5000,40,2.50,28.00

Đây chỉ là lớp giao tiếp mẫu. Không gửi các packet này vào ECU RedLeo thật cho tới khi xác định đúng protocol, checksum, baud/transport và format map.

## Safety
Sai fuel/ignition map có thể gây kích nổ, quá nhiệt hoặc hư động cơ. Test simulation trước, dùng wideband AFR và kiểm tra trên dyno khi hiệu chỉnh ECU thật.
