import UIKit

final class AppEnvironment {

    static let shared = AppEnvironment()

    let jacketStore: JacketStore
    let sessionStore: SessionStore
    let weatherService: WeatherServiceProtocol
    let alexaService: AlexaService

    private(set) var bluetoothController: BluetoothController!
    private(set) var sessionLogger: SessionLogger!

    var navigationController: UINavigationController?
    let storyBoard = UIStoryboard(name: "Main", bundle: nil)

    private init() {
        self.jacketStore = UserDefaultsJacketStore()
        self.sessionStore = UserDefaultsSessionStore()
        self.weatherService = WeatherService()
        self.alexaService = AlexaService()
    }

    /// Called once from AppDelegate after launch.
    func setup() {
        bluetoothController = BluetoothController(alexaService: alexaService)
        alexaService.delegate = bluetoothController
        sessionLogger = SessionLogger(sessionStore: sessionStore)
        SessionLogger.shared = sessionLogger
        sessionLogger.start()

        seedInputHistoryIfNeeded()
    }

    // MARK: - Temperature

    static let CELSIUS    = 1
    static let FAHRENHEIT = 2
    static let KELVIN     = 3

    private static let measureKey = "temperature_measure"
    private var cachedMeasure: Int = -1

    var temperatureMeasure: Int {
        get {
            if cachedMeasure < 0 {
                cachedMeasure = UserDefaults.standard.integer(forKey: AppEnvironment.measureKey)
            }
            return cachedMeasure
        }
        set {
            cachedMeasure = newValue
            UserDefaults.standard.set(newValue, forKey: AppEnvironment.measureKey)
        }
    }

    static func celsiusToFahrenheit(_ value: Float) -> Float {
        (value * (9.0 / 5.0)) + 32
    }

    static func fahrenheitToCelsius(_ value: Float) -> Float {
        (value - 32) / (9.0 / 5.0)
    }

    // MARK: - User Input History

    private static let inputHistoryKey = "input_history"

    func saveUserInput(newPowerLevel: Int) {
        var arr = getUserHistoryInput()
        var dic: [String: Int] = [:]
        dic[JacketGattAttributes.POWER_LEVEL.uuidString] = newPowerLevel
        dic[JacketGattAttributes.EXTERNAL_TEMPERATURE.uuidString] =
            bluetoothController.getValue(uuid: JacketGattAttributes.EXTERNAL_TEMPERATURE)
        arr.append(dic)
        if arr.count > 10 { arr.removeFirst() }
        UserDefaults.standard.set(arr, forKey: AppEnvironment.inputHistoryKey)
    }

    func getUserHistoryInput() -> [[String: Int]] {
        UserDefaults.standard.array(forKey: AppEnvironment.inputHistoryKey) as? [[String: Int]] ?? []
    }

    private func seedInputHistoryIfNeeded() {
        guard UserDefaults.standard.array(forKey: AppEnvironment.inputHistoryKey) == nil else { return }
        let seed: [[String: Int]] = [
            ["2973B788-15F2-4263-B412-8DA09F3F87F9": 0,    "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
            ["2973B788-15F2-4263-B412-8DA09F3F87F9": 200,  "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 2000],
            ["2973B788-15F2-4263-B412-8DA09F3F87F9": 250,  "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
            ["2973B788-15F2-4263-B412-8DA09F3F87F9": 100,  "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 5000],
            ["2973B788-15F2-4263-B412-8DA09F3F87F9": 0,    "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
            ["2973B788-15F2-4263-B412-8DA09F3F87F9": -210, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
            ["2973B788-15F2-4263-B412-8DA09F3F87F9": -200, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
            ["2973B788-15F2-4263-B412-8DA09F3F87F9": 0,    "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 0],
            ["2973B788-15F2-4263-B412-8DA09F3F87F9": 500,  "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 0],
            ["2973B788-15F2-4263-B412-8DA09F3F87F9": 10,   "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 5000],
        ]
        UserDefaults.standard.set(seed, forKey: AppEnvironment.inputHistoryKey)
    }

    // MARK: - Navigation

    func instantiate(id: String) -> UIViewController {
        storyBoard.instantiateViewController(withIdentifier: id)
    }

    func startViewController(_ viewController: UIViewController, clearStack: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let nav = self?.navigationController else { return }
            nav.pushViewController(viewController, animated: true)
            if clearStack {
                let count = nav.viewControllers.count
                if count > 1 {
                    nav.viewControllers.removeSubrange(0..<(count - 1))
                }
            }
        }
    }

    func removeViewControllerFromStack(_ view: UIViewController) {
        guard let nav = navigationController,
              let index = nav.viewControllers.lastIndex(of: view), index >= 0 else { return }
        nav.viewControllers.remove(at: index)
    }

    func topViewController() -> UIViewController? {
        navigationController?.viewControllers.last
    }

    // MARK: - Settings name map

    private static let settingsNames: [Int: String] = [
        Jacket.VOICE_CONTROL: "Activate voice control through \"Alexa\"",
        Jacket.LOCATION_REQUEST: "Allow location to be detected",
        Jacket.MOTION_CONTROL: "Enable Activity based Temperature control",
    ]

    static func settingName(for key: Int) -> String {
        settingsNames[key] ?? ""
    }
}
