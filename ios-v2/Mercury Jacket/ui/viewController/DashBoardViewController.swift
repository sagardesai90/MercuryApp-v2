import UIKit
import CoreBluetooth
import CoreLocation

class DashBoardViewController: BaseViewController, CLLocationManagerDelegate {

    public var TAG: String = "DashBoardViewController"
    public static var instance: DashBoardViewController!

    @IBOutlet weak var name_txt: UILabel!
    @IBOutlet weak var temperature_txt: UILabel!
    @IBOutlet weak var measure_txt: UILabel!
    @IBOutlet weak var icon: UIImageView!

    private var jacket: Jacket!
    private var bluetoothController: BluetoothController!
    private var locationManager: CLLocationManager!
    private var weatherService: WeatherServiceProtocol!

    private var subNavigationController: UINavigationController!
    private var connectedViewController: ConnectedViewController!
    private var disconnectedViewController: DisconnectedViewController!
    private var currentTemperature: Float? = nil

    private var localTemperature: Bool = false

    @IBOutlet weak var stats_button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        DashBoardViewController.instance = self

        self.bluetoothController = BluetoothController.getInstance()
        self.weatherService = AppEnvironment.shared.weatherService

        self.connectedViewController = AppController.instantiate(id: String(describing: ConnectedViewController.self)) as? ConnectedViewController
        self.disconnectedViewController = self.subNavigationController.topViewController as? DisconnectedViewController

        if #available(iOS 13.0, *) {
            stats_button?.setImage(UIImage(systemName: "chart.bar.xaxis"), for: .normal)
            stats_button?.tintColor = .white
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshTemperatureForUnitChange),
            name: .mercuryTemperatureUnitDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Keeps the dashboard number in sync when °C / °F is changed from Settings.
    @objc private func refreshTemperatureForUnitChange() {
        guard jacket != nil else { return }
        if jacket.getSetting(key: Jacket.LOCATION_REQUEST),
           let lm = locationManager {
            let status = lm.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                getLocation()
                return
            }
        }
        getLocalTemperature()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.jacket = AppController.getCurrentJacket()
        self.name_txt.text = jacket.dashboardTitleText()

        bluetoothController.listenTo(id: TAG, eventName: BluetoothController.Events.ON_SERVICES_DICOVERED) { (param) in
            guard let deviceID = param as? String, deviceID == self.jacket.id else { return }
            self.jacket = AppController.getCurrentJacket() ?? self.jacket
            self.name_txt.text = self.jacket.dashboardTitleText()
            self.bluetoothController.writeCharacteristic(uuid: JacketGattAttributes.MOTION_TEMP, value: self.jacket.getSetting(key: Jacket.MOTION_CONTROL) ? 1 : 0)
            // Firmware on some vests does not report MODE until reads settle; still show the connected UI when the link is up.
            if self.bluetoothController.isConnected() {
                self.setFragment(fragment: self.connectedViewController)
            }
        }

        bluetoothController.listenTo(id: TAG, eventName: BluetoothController.Events.ON_DEVICE_DISCONNECTED) { (param) in
            guard let arr = param as? [AnyObject], let deviceID = arr[0] as? String,
                  deviceID == self.jacket.id else { return }
            self.setFragment(fragment: self.disconnectedViewController)
        }

        bluetoothController.listenTo(id: TAG, eventName: BluetoothController.Events.ON_UPDATE_CHARACTERISTIC) { (param) in
            let params: [AnyObject] = param as! [AnyObject]
            guard let deviceID = params[0] as? String, deviceID == self.jacket.id else { return }
            let uuid: CBUUID = params[1] as! CBUUID
            let value: Int = Int(params[2] as! String)!

            var intValue: Int = Int(value)

            switch uuid.uuidString {
            case JacketGattAttributes.MODE.uuidString:
                intValue = min(intValue, 4)
                print("DASHBOARD: MODE=", intValue)
                if intValue == 0 {
                    self.bluetoothController.readCharacteristic(uuid: JacketGattAttributes.MODE)
                    if self.bluetoothController.isConnected() {
                        self.setFragment(fragment: self.connectedViewController)
                    }
                } else {
                    self.setFragment(fragment: self.connectedViewController)
                }

            case JacketGattAttributes.EXTERNAL_TEMPERATURE.uuidString:
                if self.localTemperature {
                    self.setLocalTemperature(value: intValue)
                }

            default: break
            }
        }

        if bluetoothController.isConnected() {
            setFragment(fragment: connectedViewController)
        } else {
            setFragment(fragment: disconnectedViewController)
        }
        if jacket.getSetting(key: Jacket.LOCATION_REQUEST) {
            self.locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        } else {
            self.getLocalTemperature()
        }
    }

    private func setLocalTemperature(value: Int) {
        var floatValue: Float = Float(value) / 10.0
        SessionLogger.shared.updateAmbientTemp(celsius: floatValue)
        if AppController.getTemperatureMeasure() == AppController.FAHRENHEIT {
            floatValue = AppController.celsiusToFahrenheit(value: floatValue)
        }
        self.setTemperature(value: floatValue)
    }

    private func getLocalTemperature() {
        localTemperature = true
        self.setLocalTemperature(value: bluetoothController.getValue(uuid: JacketGattAttributes.EXTERNAL_TEMPERATURE))
    }

    override func viewDidDisappear(_ animated: Bool) {
        self.bluetoothController.removeListeners(id: TAG, eventNameToRemoveOrNil: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embeded" {
            self.subNavigationController = segue.destination as? UINavigationController
        }
    }

    private func setFragment(fragment: UIViewController) {
        if self.subNavigationController.topViewController != fragment {
            if fragment.navigationController != nil {
                self.subNavigationController.popToViewController(fragment, animated: true)
            } else {
                self.subNavigationController.pushViewController(fragment, animated: true)
            }
        }
    }

    @IBAction func stats_handle(_ sender: Any) {
        AppController.startViewController(viewController: StatsViewController())
    }

    @IBAction func settings_handle(_ sender: Any) {
        AppController.startViewController(viewController: AppController.instantiate(id: String(describing: SettingsViewController.self)))
    }

    @IBAction func measure_handle(_ sender: Any) {
        if currentTemperature != nil {
            var newTemp: Float = 0

            if AppController.getTemperatureMeasure() == AppController.FAHRENHEIT {
                AppController.setTemperatureMeasure(value: AppController.CELSIUS)
                newTemp = AppController.fahrenheitToCelsius(value: currentTemperature!)
            } else {
                AppController.setTemperatureMeasure(value: AppController.FAHRENHEIT)
                newTemp = AppController.celsiusToFahrenheit(value: currentTemperature!)
            }

            setTemperature(value: Float(newTemp))
            if #available(iOS 16.2, *) {
                Task { await HeatLiveActivityManager.shared.refreshFromBluetoothState() }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        getLocation()
    }

    func getLocation() {
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            guard let currentLocation = locationManager.location else { return }
            localTemperature = false

            weatherService.fetchWeather(
                latitude: currentLocation.coordinate.latitude,
                longitude: currentLocation.coordinate.longitude
            ) { [weak self] result in
                switch result {
                case .success(let weather):
                    var temperature = weather.temperatureCelsius
                    SessionLogger.shared.updateAmbientTemp(celsius: temperature)
                    if AppController.getTemperatureMeasure() == AppController.FAHRENHEIT {
                        temperature = AppController.celsiusToFahrenheit(value: temperature)
                    }
                    self?.setTemperature(value: temperature)
                case .failure:
                    if let cached = self?.weatherService.lastKnownWeather {
                        var temp = cached.temperatureCelsius
                        SessionLogger.shared.updateAmbientTemp(celsius: temp)
                        if AppController.getTemperatureMeasure() == AppController.FAHRENHEIT {
                            temp = AppController.celsiusToFahrenheit(value: temp)
                        }
                        self?.setTemperature(value: temp)
                    } else {
                        self?.getLocalTemperature()
                    }
                }
            }
        } else {
            getLocalTemperature()
        }
    }

    func setTemperature(value: Float) {
        let work = { [weak self] in
            guard let self = self else { return }
            self.currentTemperature = value
            let unit = AppController.getTemperatureMeasure() == AppController.FAHRENHEIT ? "F" : "C"
            let displayText = AppController.getTemperatureMeasure() == AppController.CELSIUS && value < Float(-4)
                ? "Below -5" : String(format: "%.1f", value)
            self.temperature_txt.text = displayText
            self.measure_txt.text = unit
            self.icon.image = UIImage(named: self.localTemperature ? "ic_jacket" : "ic_location")

            self.temperature_txt.accessibilityLabel = "\(displayText) degrees \(unit == "F" ? "Fahrenheit" : "Celsius")"
            self.name_txt.accessibilityLabel = "Connected device: \(self.name_txt.text ?? "")"
            self.icon.accessibilityLabel = self.localTemperature ? "Temperature from jacket sensor" : "Temperature from location"
            self.stats_button?.accessibilityLabel = "View session statistics"
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}
