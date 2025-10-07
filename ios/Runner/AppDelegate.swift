import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ADVERTENCIA DE SEGURIDAD: PEGA TU CLAVE DE GOOGLE MAPS AQUÍ.
    // Este método no es seguro para producción. La clave será visible en Git.
    GMSServices.provideAPIKey("PEGA_AQUI_TU_API_KEY_DE_GOOGLE_MAPS")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}