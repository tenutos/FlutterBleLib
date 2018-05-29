#import "FlutterBleLibPlugin.h"
#import <flutter_ble_lib/flutter_ble_lib-Swift.h>

@implementation FlutterBleLibPlugin


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftFlutterBleLibPlugin registerWithRegistrar: registrar];
}

@end
