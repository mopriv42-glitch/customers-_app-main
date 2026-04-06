import UIKit
import Flutter
import CallKit
import AVFAudio
import PushKit
import flutter_callkit_incoming
import FirebaseCore
import awesome_notifications
import shared_preferences_foundation
import UserNotifications
import WebRTC


@main
@objc class AppDelegate: FlutterAppDelegate ,PKPushRegistryDelegate, CallkitIncomingAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
      self.showToast(message: "The application status is foreground")

    GeneratedPluginRegistrant.register(with: self)
//    GMSServices.provideAPIKey("AIzaSyBBy4V3KSzKPUN9hEdpXEizPIolWijpOBc")

    let controller = window?.rootViewController as! FlutterViewController
    let methodChannel = FlutterMethodChannel(name: "app_channel", binaryMessenger: controller.binaryMessenger)

    methodChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "showToast" {
        if let message = call.arguments as? String {
          self.showToast(message: message)
        }
        result(nil)
      } else if call.method == "exitApp" {
        self.exitApp()
        result(nil)
      } else if call.method == "minimizeApp" {
        self.minimizeApp()
        result(nil)
      } else if call.method == "bringToForeground" {
        self.bringToForeground()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in
        SwiftAwesomeNotificationsPlugin.register(
          with: registry.registrar(forPlugin: "io.flutter.plugins.awesomenotifications.AwesomeNotificationsPlugin")!)
        SharedPreferencesPlugin.register(
          with: registry.registrar(forPlugin: "io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin")!)
    }

    application.registerForRemoteNotifications()

    //Setup VOIP
        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
        
        //Use if using WebRTC
        RTCAudioSession.sharedInstance().useManualAudio = true
        RTCAudioSession.sharedInstance().isAudioEnabled = false
        
        //Add for Missed call notification
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        }
        

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }


 // Add for Missed call notification(show notification when foreground)
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         willPresent notification: UNNotification,
                                         withCompletionHandler completionHandler:
                                         @escaping (UNNotificationPresentationOptions) -> Void) {
        
        CallkitNotificationManager.shared.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
    }
    
    // Add for Missed call notification(action when click callback in missed notification)
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == CallkitNotificationManager.CALLBACK_ACTION {
            let data = response.notification.request.content.userInfo as? [String: Any]
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.sendCallbackEvent(data)
        }
        completionHandler()
    }
    
    
    
    // Call back from Recent history
    override func application(_ application: UIApplication,
                              continue userActivity: NSUserActivity,
                              restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        guard let handleObj = userActivity.handle else {
            return false
        }
        
        guard let isVideo = userActivity.isVideo else {
            return false
        }
        let objData = handleObj.getDecryptHandle()
        let nameCaller = objData["nameCaller"] as? String ?? ""
        let handle = objData["handle"] as? String ?? ""
        let data = flutter_callkit_incoming.Data(id: UUID().uuidString, nameCaller: nameCaller, handle: handle, type: isVideo ? 1 : 0)
        //set more data...
        //data.nameCaller = nameCaller
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.startCall(data, fromPushKit: true)
        
        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
    
    // Handle updated push credentials
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print(credentials.token)
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        print(deviceToken)
        //Save deviceToken to your server
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("didInvalidatePushTokenFor")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
    }
    
    // Handle incoming pushes
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("didReceiveIncomingPushWith")
        guard type == .voIP else { return }
        
        let id = payload.dictionaryPayload["id"] as? String ?? ""
        let nameCaller = payload.dictionaryPayload["nameCaller"] as? String ?? ""
        let handle = payload.dictionaryPayload["handle"] as? String ?? ""
        let isVideo = payload.dictionaryPayload["isVideo"] as? Bool ?? false
        
        let data = flutter_callkit_incoming.Data(id: id, nameCaller: nameCaller, handle: handle, type: isVideo ? 1 : 0)
        //set more data
        data.extra = ["user": "abc@123", "platform": "ios"]
        //data.iconName = ...
        //data.....
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true){
            completion()
        }
        
    }
    
    
    // Func Call api for Accept
    func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
        let json = ["action": "ACCEPT", "data": call.data.toJSON()] as [String: Any]
        print("LOG: onAccept")
        self.performRequest(parameters: json) { result in
            switch result {
            case .success(let data):
                print("Received data: \(data)")
                //Make sure call action.fulfill() when you are done(connected WebRTC - Start counting seconds)
                action.fulfill()
                
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    // Func Call API for Decline
    func onDecline(_ call: Call, _ action: CXEndCallAction) {
        let json = ["action": "DECLINE", "data": call.data.toJSON()] as [String: Any]
        print("LOG: onDecline")
        self.performRequest(parameters: json) { result in
            switch result {
            case .success(let data):
                print("Received data: \(data)")
                //Make sure call action.fulfill() when you are done
                action.fulfill()
                
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    // Func Call API for End
    func onEnd(_ call: Call, _ action: CXEndCallAction) {
        let json = ["action": "END", "data": call.data.toJSON()] as [String: Any]
        print("LOG: onEnd")
        self.performRequest(parameters: json) { result in
            switch result {
            case .success(let data):
                print("Received data: \(data)")
                //Make sure call action.fulfill() when you are done
                action.fulfill()
                
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    // Func Call API for TimeOut
    func onTimeOut(_ call: Call) {
        let json = ["action": "TIMEOUT", "data": call.data.toJSON()] as [String: Any]
        print("LOG: onTimeOut")
        self.performRequest(parameters: json) { result in
            switch result {
            case .success(let data):
                print("Received data: \(data)")
                
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    // Func Callback Toggle Audio Session
    func didActivateAudioSession(_ audioSession: AVAudioSession) {
        //Use if using WebRTC
        RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
        RTCAudioSession.sharedInstance().isAudioEnabled = true
    }
    
    // Func Callback Toggle Audio Session
    func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
        //Use if using WebRTC
        RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
        RTCAudioSession.sharedInstance().isAudioEnabled = false
    }
    
    func performRequest(parameters: [String: Any], completion: @escaping (Result<Any, Error>) -> Void) {
        // Removed third-party tracking (was sending data to https://events.hiennv.com/api/logs)
        completion(.success(["status": "ignored"]))
    }
    

  private func showToast(message: String) {

  }

  private func exitApp() {
    // NOTE: Do NOT use exit(0) on iOS — Apple will REJECT your app.
    // Apple considers exit(0) to be a crash. Instead, suspend to home screen.
    UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
  }

  private func minimizeApp() {
    if let url = URL(string: "private-4t://") {
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }
  }

  private func bringToForeground() {
    // لا يوجد مكافئ مباشر لهذه الدالة في iOS. يمكنك توضيح ذلك للمستخدمين.
  }


}
