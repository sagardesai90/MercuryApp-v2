import Foundation
import LoginWithAmazon

protocol AlexaServiceDelegate: AnyObject {
    func alexaService(_ service: AlexaService, didReceiveMode mode: Int)
}

final class AlexaService: NSObject, AIAuthenticationDelegate {

    private let alexaURL: String
    private var email: String?
    private var activeTask: URLSessionDataTask?

    weak var delegate: AlexaServiceDelegate?

    init(alexaURL: String = "https://x0i55e3ypk.execute-api.us-east-1.amazonaws.com/prod/?email=%@") {
        self.alexaURL = alexaURL
        super.init()
    }

    func checkVoiceControl(voiceEnabled: Bool) {
        if voiceEnabled && email == nil {
            AIMobileLib.getProfile(self)
        } else if email != nil && !voiceEnabled {
            email = nil
        } else if email != nil && voiceEnabled {
            loadAlexaStatus()
        }
    }

    func reset() {
        activeTask?.cancel()
        activeTask = nil
        email = nil
    }

    // MARK: - Private

    private func loadAlexaStatus() {
        guard activeTask == nil, let email = email else { return }
        let urlString = String(format: alexaURL, email)
        guard let url = URL(string: urlString) else { return }

        print("URL_GET_STATUS", urlString)
        activeTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            defer { self?.activeTask = nil }
            guard let data = data, error == nil else {
                print("jacketStatus error")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let status = json?["jacketStatus"] as? Int ?? -1
                print("JACKETSTATUS", status)
                if status > -1 {
                    DispatchQueue.main.async {
                        self?.delegate?.alexaService(self!, didReceiveMode: status)
                    }
                }
            } catch {
                print("jacketStatus parse error:", error)
            }
        }
        activeTask?.resume()
    }

    // MARK: - AIAuthenticationDelegate

    func requestDidSucceed(_ apiResult: APIResult!) {
        DispatchQueue.main.async {
            self.email = (apiResult?.result as? [AnyHashable: Any])?["email"] as? String
            print("AMAZON_RESULT", apiResult?.result as Any)
            if self.email != nil { self.loadAlexaStatus() }
        }
    }

    func requestDidFail(_ errorResponse: APIError!) {
        print("Error:", errorResponse.error.message ?? "nil")
    }
}
