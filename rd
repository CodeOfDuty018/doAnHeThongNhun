#define BLYNK_TEMPLATE_ID "TMPL6oPuPBnfA"
#define BLYNK_TEMPLATE_NAME "thuNhunSys"
#define BLYNK_PRINT Serial

#include <WiFi.h>
#include <WebServer.h>
#include <BlynkSimpleEsp32.h>

// Thông tin Access Point
const char* ssidAP = "ESP32-CAM";    // Tên AP mà ESP32-CAM sẽ phát
const char* passwordAP = "12345678"; // Mật khẩu cho AP

WebServer server(80);  // Tạo máy chủ web trên cổng 80

// Biến lưu SSID và mật khẩu WiFi
String wifiSSID = "";
String wifiPassword = "";

// Chân GPIO4 được sử dụng để điều khiển thiết bị (LED/Quạt)
//const int quatPin = 4;
WidgetTerminal terminal(V1);  // Widget Terminal trên Blynk
int ledStatus = 0;
const int rxPin = 16;  // ESP32 RX pin (connect to ESP8266 TX)
const int txPin = 17;  // ESP32 TX pin (connect to ESP8266 RX)
HardwareSerial SerialESP(1);  // Use second serial for UART communication

// Thay thế YOUR_BLYNK_AUTH_TOKEN bằng mã thông báo xác thực Blynk của bạn
char auth[] = "h5pCAUpHcvoRCdI1PCHq8JOa__12AJQk";

// Trang HTML đơn giản để nhập SSID và mật khẩu WiFi
const char* htmlForm = R"rawliteral(
  <html>
  <body>
    <h1>Kết nối với WiFi</h1>
    <form action="/get">
      SSID: <input type="text" name="ssid"><br>
      Password: <input type="password" name="password"><br>
      <input type="submit" value="Kết nối">
    </form>
  </body>
  </html>)rawliteral";

// Hàm hiển thị trang chủ HTML cho người dùng nhập SSID và mật khẩu
void handleRoot() {
  server.send(200, "text/html", htmlForm);
}

// Hàm xử lý khi người dùng gửi thông tin SSID và mật khẩu
void handleSubmit() {
  wifiSSID = server.arg("ssid");
  wifiPassword = server.arg("password");
  
  // Gửi phản hồi đến trang web và kết nối WiFi
  server.send(200, "text/html", "<h1>Đang kết nối...</h1>");
  delay(1000);  // Chờ 1 giây

  WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());
  Serial.println("Đang kết nối tới WiFi...");
  
  // Thử kết nối với WiFi trong vòng 10 giây
  int timeout = 10;
  while (WiFi.status() != WL_CONNECTED && timeout > 0) {
    delay(1000);
    Serial.print(".");
    timeout--;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nKết nối thành công!");
    Serial.println("Địa chỉ IP: ");
    Serial.println(WiFi.localIP());

    // Kết nối Blynk
    Blynk.begin(auth, WiFi.SSID().c_str(), WiFi.psk().c_str());

    server.send(200, "text/html", "<h1>Kết nối thành công!</h1>");
  } else {
    Serial.println("\nKết nối thất bại.");
    server.send(200, "text/html", "<h1>Kết nối thất bại. Vui lòng thử lại.</h1>");
  }
}

void setup() {
  Serial.begin(115200);

  // Thiết lập ESP32 ở chế độ Access Point
  Serial.println("Đang thiết lập Access Point...");
  WiFi.softAP(ssidAP, passwordAP);

  // Hiển thị địa chỉ IP của Access Point
  Serial.print("AP IP address: ");
  Serial.println(WiFi.softAPIP());

  // Thiết lập chế độ xuất cho chân GPIO4
  //pinMode(quatPin, OUTPUT);

  // Cài đặt route cho máy chủ web
  server.on("/", handleRoot);          // Route trang chủ
  server.on("/get", handleSubmit);     // Route xử lý khi submit form
  server.begin();
  Serial.println("Máy chủ web đã sẵn sàng.");

  // Start UART communication between ESP32 and ESP8266
  SerialESP.begin(9600, SERIAL_8N1, rxPin, txPin);
}

void loop() {
  server.handleClient();  // Duy trì hoạt động của máy chủ web
  Blynk.run();            // Duy trì kết nối Blynk
}

// Hàm để bật tắt thiết bị (LED/Quạt) thông qua Blynk
BLYNK_WRITE(V0) {
  ledStatus = param.asInt();  // Get the button state from Blynk
  if (ledStatus == 1) {
    SerialESP.print("ON");  // Send ON command to ESP8266
  } else {
    SerialESP.print("OFF"); // Send OFF command to ESP8266
  }
}

// Hàm để xử lý dữ liệu từ Terminal Blynk
BLYNK_WRITE(V1) {
  if (String("helo") == param.asStr()) {
    terminal.println("You said: 'helo'");
    terminal.println("I said: 'lo lo con c'");
  } else {
    terminal.print("You said: ");
    terminal.write(param.getBuffer(), param.getLength());
    terminal.println();
  }
  terminal.flush();  // Đảm bảo dữ liệu được gửi đầy đủ
}
