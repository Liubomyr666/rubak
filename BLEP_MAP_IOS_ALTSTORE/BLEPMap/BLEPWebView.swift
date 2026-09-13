import SwiftUI
import WebKit
import CoreLocation
import UIKit

struct BLEPWebView: UIViewRepresentable {
    let serverURL: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()

        controller.add(context.coordinator, name: "blepLocation")
        controller.add(context.coordinator, name: "blepHaptic")

        let locationBridge = WKUserScript(
            source: Self.locationBridgeScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        controller.addUserScript(locationBridge)

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.customUserAgent = "BLEPMap-iOS/1.0 WKWebView"

        context.coordinator.webView = webView

        if let url = URL(string: serverURL) {
            webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let current = webView.url?.absoluteString,
              let target = URL(string: serverURL)?.absoluteString else {
            if let url = URL(string: serverURL) {
                webView.load(URLRequest(url: url))
            }
            return
        }

        let currentHost = URL(string: current)?.host
        let targetHost = URL(string: target)?.host
        if currentHost != targetHost {
            webView.load(URLRequest(url: URL(string: target)!))
        }
    }

    static let locationBridgeScript = #"""
    (() => {
      if (window.__blepNativeLocationInstalled) return;
      window.__blepNativeLocationInstalled = true;

      let seq = 0;
      const once = new Map();
      const watch = new Map();

      function send(kind, payload) {
        try {
          window.webkit.messageHandlers.blepLocation.postMessage({ kind, ...payload });
        } catch (_) {}
      }

      window.__blepLocationResult = function(id, ok, payload) {
        const table = id.startsWith("w") ? watch : once;
        const cb = table.get(id);
        if (!cb) return;

        if (ok) {
          cb.success({
            coords: {
              latitude: payload.latitude,
              longitude: payload.longitude,
              accuracy: payload.accuracy,
              altitude: payload.altitude,
              altitudeAccuracy: payload.altitudeAccuracy,
              heading: payload.heading,
              speed: payload.speed
            },
            timestamp: payload.timestamp
          });
        } else if (cb.error) {
          cb.error({
            code: payload.code || 2,
            message: payload.message || "Location unavailable"
          });
        }

        if (!id.startsWith("w")) once.delete(id);
      };

      const geo = {
        getCurrentPosition(success, error, options) {
          const id = "o" + (++seq);
          once.set(id, { success, error });
          send("once", { id, highAccuracy: !!(options && options.enableHighAccuracy) });
        },
        watchPosition(success, error, options) {
          const id = "w" + (++seq);
          watch.set(id, { success, error });
          send("watch", { id, highAccuracy: !!(options && options.enableHighAccuracy) });
          return id;
        },
        clearWatch(id) {
          watch.delete(String(id));
          send("clear", { id: String(id) });
        }
      };

      try {
        Object.defineProperty(navigator, "geolocation", {
          configurable: true,
          value: geo
        });
      } catch (_) {
        try { navigator.geolocation = geo; } catch (_) {}
      }

      try {
        navigator.vibrate = function(pattern) {
          window.webkit.messageHandlers.blepHaptic.postMessage({ pattern });
          return true;
        };
      } catch (_) {}
    })();
    """#

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, CLLocationManagerDelegate {
        weak var webView: WKWebView?

        private let locationManager = CLLocationManager()
        private var oneShotIDs = Set<String>()
        private var watchIDs = Set<String>()

        override init() {
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 3
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any] else { return }

            if message.name == "blepHaptic" {
                DispatchQueue.main.async {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.prepare()
                    generator.impactOccurred()
                }
                return
            }

            guard message.name == "blepLocation",
                  let kind = body["kind"] as? String,
                  let id = body["id"] as? String else { return }

            switch kind {
            case "once":
                oneShotIDs.insert(id)
                ensureLocation()
            case "watch":
                watchIDs.insert(id)
                ensureLocation()
            case "clear":
                watchIDs.remove(id)
                if watchIDs.isEmpty && oneShotIDs.isEmpty {
                    locationManager.stopUpdatingLocation()
                }
            default:
                break
            }
        }

        private func ensureLocation() {
            let status = locationManager.authorizationStatus
            switch status {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.startUpdatingLocation()
            case .denied, .restricted:
                emitErrorToAll(code: 1, message: "Location permission denied")
            @unknown default:
                emitErrorToAll(code: 2, message: "Location unavailable")
            }
        }

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                emitErrorToAll(code: 1, message: "Location permission denied")
            default:
                break
            }
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let loc = locations.last else { return }

            let payload: [String: Any] = [
                "latitude": loc.coordinate.latitude,
                "longitude": loc.coordinate.longitude,
                "accuracy": loc.horizontalAccuracy,
                "altitude": loc.altitude,
                "altitudeAccuracy": loc.verticalAccuracy,
                "heading": loc.course >= 0 ? loc.course : NSNull(),
                "speed": loc.speed >= 0 ? loc.speed : NSNull(),
                "timestamp": loc.timestamp.timeIntervalSince1970 * 1000
            ]

            let onceNow = oneShotIDs
            for id in onceNow {
                emit(id: id, ok: true, payload: payload)
            }
            oneShotIDs.removeAll()

            for id in watchIDs {
                emit(id: id, ok: true, payload: payload)
            }

            if watchIDs.isEmpty {
                manager.stopUpdatingLocation()
            }
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            emitErrorToAll(code: 2, message: error.localizedDescription)
        }

        private func emitErrorToAll(code: Int, message: String) {
            let payload: [String: Any] = ["code": code, "message": message]
            let all = oneShotIDs.union(watchIDs)
            for id in all {
                emit(id: id, ok: false, payload: payload)
            }
            oneShotIDs.removeAll()
            watchIDs.removeAll()
            locationManager.stopUpdatingLocation()
        }

        private func emit(id: String, ok: Bool, payload: [String: Any]) {
            guard let webView else { return }
            guard let data = try? JSONSerialization.data(withJSONObject: payload),
                  let json = String(data: data, encoding: .utf8) else { return }

            let safeID = id.replacingOccurrences(of: "'", with: "\\'")
            let js = "window.__blepLocationResult('\(safeID)', \(ok ? "true" : "false"), \(json));"
            DispatchQueue.main.async {
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let css = """
            document.documentElement.style.setProperty('--blep-safe-top', 'env(safe-area-inset-top)');
            document.documentElement.style.setProperty('--blep-safe-bottom', 'env(safe-area-inset-bottom)');
            """
            webView.evaluateJavaScript(css, completionHandler: nil)
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                UIApplication.shared.open(url)
            }
            return nil
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let scheme = navigationAction.request.url?.scheme?.lowercased(),
               !["http", "https", "about", "blob", "data"].contains(scheme) {
                if let url = navigationAction.request.url {
                    UIApplication.shared.open(url)
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
