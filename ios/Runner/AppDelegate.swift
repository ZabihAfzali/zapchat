import UIKit
import Flutter
import FBSDKCoreKit // For Facebook
import GoogleSignIn  // Only needed if using google_sign_in plugin directly

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Facebook SDK initialization
    ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle URL opening for Google & Facebook
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {

    let handledFB = ApplicationDelegate.shared.application(
        app,
        open: url,
        sourceApplication: options[.sourceApplication] as? String,
        annotation: options[.annotation]
    )

    let handledGoogle = GIDSignIn.sharedInstance.handle(url)

    return handledFB || handledGoogle
  }
}