import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps with API key from GoogleService-Info.plist
    // This MUST happen before GeneratedPluginRegistrant.register to ensure
    // the API key is set before any Google Maps widgets are created
    var apiKeyFound = false
    
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: path),
       let apiKey = dict["API_KEY"] as? String,
       !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
      apiKeyFound = true
      print("Google Maps API key loaded from GoogleService-Info.plist")
    } else {
      // Fallback: try reading from Info.plist with GMSApiKey
      if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
         let dict = NSDictionary(contentsOfFile: path),
         let apiKey = dict["GMSApiKey"] as? String,
         !apiKey.isEmpty {
        GMSServices.provideAPIKey(apiKey)
        apiKeyFound = true
        print("Google Maps API key loaded from Info.plist")
      }
    }
    
    if !apiKeyFound {
      print("WARNING: Google Maps API key not found! Map features will not work.")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
