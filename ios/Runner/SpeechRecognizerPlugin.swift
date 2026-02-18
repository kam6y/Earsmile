import Flutter
import Speech
import AVFoundation

/// Flutter Platform Channel を通じて SFSpeechRecognizer を制御するプラグイン
///
/// MethodChannel: com.app.speech/recognizer
///   - startListening / stopListening / requestPermission / checkPermission
///
/// EventChannel: com.app.speech/recognizer_events
///   - onPartialResult / onFinalResult / onError / onSilenceDetected
class SpeechRecognizerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    // MARK: - Channel 定数

    private static let methodChannelName = "com.app.speech/recognizer"
    private static let eventChannelName = "com.app.speech/recognizer_events"

    // MARK: - プロパティ

    private let speechRecognizer: SFSpeechRecognizer
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var eventSink: FlutterEventSink?

    // 無音検知用
    private var silenceTimer: Timer?
    private let silenceThreshold: Float = 0.05
    private let silenceDuration: TimeInterval = 1.5

    // 認識中フラグ（セッション自動再起動の制御用）
    private var isListening = false

    // MARK: - 初期化

    override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
        super.init()
    }

    // MARK: - FlutterPlugin プロトコル

    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SpeechRecognizerPlugin()

        let methodChannel = FlutterMethodChannel(
            name: methodChannelName,
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(
            name: eventChannelName,
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
    }

    // MARK: - MethodChannel ハンドラ

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startListening":
            startListening(result: result)
        case "stopListening":
            stopListening(result: result)
        case "requestPermission":
            requestPermission(result: result)
        case "checkPermission":
            checkPermission(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FlutterStreamHandler プロトコル

    func onListen(withArguments arguments: Any?,
                  eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    // MARK: - 権限管理

    private func checkPermission(result: @escaping FlutterResult) {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVAudioSession.sharedInstance().recordPermission

        if speechStatus == .authorized && micStatus == .granted {
            result("granted")
        } else if speechStatus == .denied || micStatus == .denied {
            result("denied")
        } else {
            result("notDetermined")
        }
    }

    private func requestPermission(result: @escaping FlutterResult) {
        SFSpeechRecognizer.requestAuthorization { [weak self] speechStatus in
            guard let self = self else { return }

            guard speechStatus == .authorized else {
                DispatchQueue.main.async { result(false) }
                return
            }

            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async { result(granted) }
            }
        }
    }

    // MARK: - 音声認識制御

    private func startListening(result: @escaping FlutterResult) {
        // 既存のセッションがあれば停止
        if recognitionTask != nil {
            stopCurrentSession()
        }

        // オーディオセッション設定
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            sendError(code: "AUDIO_SESSION_ERROR", message: error.localizedDescription)
            result(FlutterError(code: "AUDIO_SESSION_ERROR",
                                message: error.localizedDescription, details: nil))
            return
        }

        // 認識リクエスト作成
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            result(FlutterError(code: "REQUEST_INIT_ERROR",
                                message: "認識リクエストを作成できませんでした", details: nil))
            return
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true

        // 認識タスク開始
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) {
            [weak self] taskResult, error in
            guard let self = self else { return }

            if let error = error {
                // 認識中でなければ（手動停止の場合）エラーを無視
                guard self.isListening else { return }
                self.sendError(code: "RECOGNITION_ERROR", message: error.localizedDescription)
                self.stopCurrentSession()
                return
            }

            guard let taskResult = taskResult else { return }

            let text = taskResult.bestTranscription.formattedString
            let confidence: Double = taskResult.bestTranscription.segments.last
                .map { Double($0.confidence) } ?? 0.0

            if taskResult.isFinal {
                self.sendEvent(type: "onFinalResult",
                               data: ["text": text, "confidence": confidence])
                self.silenceTimer?.invalidate()
                self.silenceTimer = nil

                // iOS の約60秒制限対策: isFinal を受けたらセッションを再起動
                if self.isListening {
                    self.stopCurrentSession()
                    // 少し遅延を入れてから再起動
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        guard let self = self, self.isListening else { return }
                        self.startNewRecognitionSession()
                    }
                }
            } else {
                self.sendEvent(type: "onPartialResult",
                               data: ["text": text, "confidence": confidence])
            }
        }

        // オーディオタップ設定（音声レベル監視 + 認識バッファ投入）
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            [weak self] buffer, _ in
            guard let self = self else { return }

            self.recognitionRequest?.append(buffer)

            let level = self.calculateRMSLevel(buffer: buffer)
            self.handleAudioLevel(level)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
            result(nil)
        } catch {
            sendError(code: "AUDIO_ENGINE_ERROR", message: error.localizedDescription)
            result(FlutterError(code: "AUDIO_ENGINE_ERROR",
                                message: error.localizedDescription, details: nil))
        }
    }

    /// 認識セッションのみを再起動（オーディオエンジンは維持）
    private func startNewRecognitionSession() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) {
            [weak self] taskResult, error in
            guard let self = self else { return }

            if let error = error {
                guard self.isListening else { return }
                self.sendError(code: "RECOGNITION_ERROR", message: error.localizedDescription)
                self.stopCurrentSession()
                return
            }

            guard let taskResult = taskResult else { return }

            let text = taskResult.bestTranscription.formattedString
            let confidence: Double = taskResult.bestTranscription.segments.last
                .map { Double($0.confidence) } ?? 0.0

            if taskResult.isFinal {
                self.sendEvent(type: "onFinalResult",
                               data: ["text": text, "confidence": confidence])
                self.silenceTimer?.invalidate()
                self.silenceTimer = nil

                if self.isListening {
                    self.stopCurrentSession()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        guard let self = self, self.isListening else { return }
                        self.startNewRecognitionSession()
                    }
                }
            } else {
                self.sendEvent(type: "onPartialResult",
                               data: ["text": text, "confidence": confidence])
            }
        }
    }

    private func stopListening(result: @escaping FlutterResult) {
        isListening = false
        stopCurrentSession()
        result(nil)
    }

    private func stopCurrentSession() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    // MARK: - 無音検知

    private func calculateRMSLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }
        let channelDataValue = channelData.pointee
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0.0 }

        var sum: Float = 0.0
        for i in 0..<frames {
            sum += channelDataValue[i] * channelDataValue[i]
        }
        return sqrtf(sum / Float(frames))
    }

    private func handleAudioLevel(_ level: Float) {
        if level < silenceThreshold {
            if silenceTimer == nil {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.silenceTimer = Timer.scheduledTimer(
                        withTimeInterval: self.silenceDuration,
                        repeats: false
                    ) { [weak self] _ in
                        self?.onSilenceDetected()
                    }
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.silenceTimer?.invalidate()
                self?.silenceTimer = nil
            }
        }
    }

    private func onSilenceDetected() {
        sendEvent(type: "onSilenceDetected", data: [:])
        silenceTimer = nil
    }

    // MARK: - EventChannel 送信ヘルパー

    private func sendEvent(type: String, data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            var payload = data
            payload["type"] = type
            self?.eventSink?(payload)
        }
    }

    private func sendError(code: String, message: String) {
        sendEvent(type: "onError", data: ["errorCode": code, "message": message])
    }
}
