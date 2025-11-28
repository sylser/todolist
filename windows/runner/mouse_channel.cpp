#include "mouse_channel.h"
#include <windows.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <memory>

void SetupMouseChannel(flutter::FlutterEngine* engine) {
  if (!engine) {
    return;
  }
  
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          engine->messenger(), "com.todolist/mouse",
          &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "getMousePosition") {
          POINT point;
          if (GetCursorPos(&point)) {
            flutter::EncodableMap position;
            position[flutter::EncodableValue("x")] = flutter::EncodableValue(static_cast<double>(point.x));
            position[flutter::EncodableValue("y")] = flutter::EncodableValue(static_cast<double>(point.y));
            result->Success(flutter::EncodableValue(position));
          } else {
            result->Error("UNAVAILABLE", "Failed to get mouse position");
          }
        } else if (call.method_name() == "getScreenSize") {
          int width = GetSystemMetrics(SM_CXSCREEN);
          int height = GetSystemMetrics(SM_CYSCREEN);
          flutter::EncodableMap size;
          size[flutter::EncodableValue("width")] = flutter::EncodableValue(static_cast<double>(width));
          size[flutter::EncodableValue("height")] = flutter::EncodableValue(static_cast<double>(height));
          result->Success(flutter::EncodableValue(size));
        } else {
          result->NotImplemented();
        }
      });
}

