import Flutter
import UIKit

@available(iOS 13.0, *)
@objc(SceneDelegate)
class SceneDelegate: FlutterSceneDelegate {
  let flutterEngine = FlutterEngine(name: "my flutter engine")

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let window = UIWindow(windowScene: windowScene)

    // Start engine and register plugins
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)

    // Create Flutter view controller
    let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    window.rootViewController = flutterViewController
    window.makeKeyAndVisible()
    self.window = window

    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
