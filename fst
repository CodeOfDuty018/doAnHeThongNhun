#define BLYNK_TEMPLATE_ID "TMPL6oPuPBnfA"
#define BLYNK_TEMPLATE_NAME "thuNhunSys"
#define BLYNK_PRINT Serial

#include <WiFi.h>
#include <WebServer.h>
#include <BlynkSimpleEsp32.h>

const char* ssidAP = "ESP32-CAM"; // Tên AP mà ESP32-CAM sẽ phát
const char* passwordAP = "12345678"; // Mật khẩu cho AP

WebServer server(80); // Tạo máy chủ web trên cổng 80

String wifiSSID = "";
String wifiPassword = "";

const int quatPin = 4; // Chân GPIO4 của LED
WidgetTerminal terminal(V1);

// Thay thế YOUR_BLYNK_AUTH_TOKEN bằng mã thông báo xác thực Blynk của bạn
char auth[] = "TfmLIEos7K6krgXvc0F-vrNZP4mrLRtJ";

// Trang HTML đơn giản để người dùng nhập SSID và mật khẩu WiFi
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

// Hàm xử lý khi người dùng nhập SSID và mật khẩu
void handleRoot() {
  server.send(200, "text/html", htmlForm);
}

void handleSubmit() {
  wifiSSID = server.arg("ssid");
  wifiPassword = server.arg("password");
  
  server.send(200, "text/html", "<h1>Đang kết nối...</h1>");
  delay(1000); // Chờ một chút rồi kết nối

  // Thử kết nối với WiFi mà người dùng nhập
  WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());

  Serial.println("Đang kết nối tới WiFi...");
  int timeout = 10; // Chờ tối đa 10 giây
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
  
  // Thiết lập ESP32 ở chế độ AP
  Serial.println("Đang thiết lập Access Point...");
  WiFi.softAP(ssidAP, passwordAP);

  // Hiển thị địa chỉ IP của AP
  Serial.print("AP IP address: ");
  Serial.println(WiFi.softAPIP());

  pinMode(quatPin, OUTPUT); // Thiết lập pin LED

  // Cài đặt các route cho máy chủ web
  server.on("/", handleRoot);          // Route cho trang chủ (form nhập thông tin)
  server.on("/get", handleSubmit);     // Route xử lý khi submit form
  server.begin();
  Serial.println("Máy chủ web đã sẵn sàng.");
}

void loop() {
  // Duy trì hoạt động của máy chủ web
  server.handleClient();
  
  // Duy trì kết nối Blynk
  Blynk.run();

  // Cứ mỗi 4 giây gửi tin nhắn lên Terminal
  static unsigned long lastTime = 0;
  unsigned long currentTime = millis();
  
  if (currentTime - lastTime >= 4000) {  // 4 giây
    lastTime = currentTime;
    
    terminal.println("Tin nhắn từ ESP32-CAM gửi lên Terminal!");
    terminal.flush();  // Đẩy dữ liệu lên ngay
  }
}

// Hàm để bật tắt LED thông qua Blynk
BLYNK_WRITE(V0){ // V0 là Virtual Pin mà bạn đã chọn trong ứng dụng Blynk
  int pinValue = param.asInt(); // Đọc giá trị từ Blynk
  digitalWrite(quatPin, pinValue); // Bật hoặc tắt LED
}
