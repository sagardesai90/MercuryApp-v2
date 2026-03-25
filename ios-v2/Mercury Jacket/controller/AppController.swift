import UIKit

/// Thin facade over `AppEnvironment` — preserved for backward compatibility.
/// New code should use `AppEnvironment.shared` directly.
class AppController {

    public static var storyBoard: UIStoryboard { AppEnvironment.shared.storyBoard }

    public static let KEY_JACKETS: String = "jackets"
    public static let KEY_CURRENT_JACKET: String = "current_jacket"
    public static let KEY_AMAZON_TOKEN: String = "amazon_token"
    public static let AMAZON_SCOPE: [String] = ["profile"]

    public static let CELSIUS    = AppEnvironment.CELSIUS
    public static let FAHRENHEIT = AppEnvironment.FAHRENHEIT
    public static let KELVIN     = AppEnvironment.KELVIN

    public static var navigationController: UINavigationController? {
        get { AppEnvironment.shared.navigationController }
        set { AppEnvironment.shared.navigationController = newValue }
    }

    public static func setup() {
        AppEnvironment.shared.setup()
    }

    public static func getSettingName(key: Int) -> String {
        AppEnvironment.settingName(for: key)
    }

    public static func getCurrentJacket() -> Jacket? {
        AppEnvironment.shared.jacketStore.currentJacket
    }

    public static func addJacket(jacket: Jacket) {
        AppEnvironment.shared.jacketStore.addJacket(jacket)
    }

    public static func removeJacket(jacket: Jacket) {
        AppEnvironment.shared.jacketStore.removeJacket(jacket)
    }

    public static func getJacketsList() -> [Jacket] {
        AppEnvironment.shared.jacketStore.allJackets()
    }

    public static func saveUserInput(newPowerLevel: Int) {
        AppEnvironment.shared.saveUserInput(newPowerLevel: newPowerLevel)
    }

    public static func getUserHistoryInput() -> [[String: Int]] {
        AppEnvironment.shared.getUserHistoryInput()
    }

    public static func connectedTo(jacket: Jacket?) {
        AppEnvironment.shared.jacketStore.setCurrentJacket(jacket)
    }

    public static func hasJacket() -> Bool {
        AppEnvironment.shared.jacketStore.hasCurrentJacket()
    }

    public static func hasJackets() -> Bool {
        AppEnvironment.shared.jacketStore.hasAnyJackets()
    }

    public static func setTemperatureMeasure(value: Int) {
        AppEnvironment.shared.temperatureMeasure = value
    }

    public static func getTemperatureMeasure() -> Int {
        AppEnvironment.shared.temperatureMeasure
    }

    public static func celsiusToFahrenheit(value: Float) -> Float {
        AppEnvironment.celsiusToFahrenheit(value)
    }

    public static func fahrenheitToCelsius(value: Float) -> Float {
        AppEnvironment.fahrenheitToCelsius(value)
    }

    public static func instantiate(id: String) -> UIViewController {
        AppEnvironment.shared.instantiate(id: id)
    }

    public static func startViewController(viewController: UIViewController, clearStack: Bool = false) {
        AppEnvironment.shared.startViewController(viewController, clearStack: clearStack)
    }

    public static func removeViewControllerFromStack(view: UIViewController) {
        AppEnvironment.shared.removeViewControllerFromStack(view)
    }

    public static func getContext() -> UIViewController {
        AppEnvironment.shared.topViewController()!
    }
}
