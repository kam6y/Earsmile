import AVFoundation
import Flutter
import Speech

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

    private let speechLocale = Locale(identifier: "ja-JP")
    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var eventSink: FlutterEventSink?

    // 無音検知用
    private var silenceTimer: Timer?
    private let silenceThreshold: Float = 0.05
    private let silenceDuration: TimeInterval = 1.5

    // 認識中フラグ（セッション自動再起動の制御用）
    private var isListening = false
    private var hasInstalledTap = false

    // MARK: - 初期化

    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: speechLocale)
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
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
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
        SFSpeechRecognizer.requestAuthorization { speechStatus in
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
        guard let recognizer = speechRecognizer else {
            let message = "音声認識が利用できません"
            sendError(code: "RECOGNIZER_UNAVAILABLE", message: message)
            result(FlutterError(code: "RECOGNIZER_UNAVAILABLE", message: message, details: nil))
            return
        }

        guard recognizer.isAvailable else {
            let message = "音声認識が一時的に利用できません"
            sendError(code: "RECOGNIZER_NOT_AVAILABLE", message: message)
            result(FlutterError(code: "RECOGNIZER_NOT_AVAILABLE", message: message, details: nil))
            return
        }

        guard SFSpeechRecognizer.authorizationStatus() == .authorized,
              AVAudioSession.sharedInstance().recordPermission == .granted else {
            let message = "マイクまたは音声認識の権限がありません"
            sendError(code: "PERMISSION_DENIED", message: message)
            result(FlutterError(code: "PERMISSION_DENIED", message: message, details: nil))
            return
        }

        if #available(iOS 13.0, *), !recognizer.supportsOnDeviceRecognition {
            let message = "この端末ではオンデバイス音声認識を利用できません"
            sendError(code: "ON_DEVICE_NOT_SUPPORTED", message: message)
            result(FlutterError(code: "ON_DEVICE_NOT_SUPPORTED", message: message, details: nil))
            return
        }

        // 既存のセッションがあれば停止
        if recognitionTask != nil || audioEngine.isRunning || hasInstalledTap {
            stopCurrentSession()
        }

        guard createRecognitionRequest() else {
            let message = "認識リクエストを作成できませんでした"
            sendError(code: "REQUEST_INIT_ERROR", message: message)
            result(FlutterError(code: "REQUEST_INIT_ERROR", message: message, details: nil))
            return
        }

        // オーディオセッション設定
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            let message = "音声入力の初期化に失敗しました"
            sendError(code: "AUDIO_SESSION_ERROR", message: message)
            result(FlutterError(code: "AUDIO_SESSION_ERROR", message: message, details: nil))
            return
        }

        startRecognitionTask(with: recognizer)
        installInputTap()

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
            result(nil)
        } catch {
            let message = "音声認識の開始に失敗しました"
            sendError(code: "AUDIO_ENGINE_ERROR", message: message)
            stopCurrentSession()
            result(FlutterError(code: "AUDIO_ENGINE_ERROR", message: message, details: nil))
        }
    }

    private func stopListening(result: @escaping FlutterResult) {
        isListening = false
        stopCurrentSession()
        result(nil)
    }

    private func startRecognitionTask(with recognizer: SFSpeechRecognizer) {
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) {
            [weak self] taskResult, error in
            guard let self = self else { return }

            if error != nil {
                // 認識中でなければ（手動停止の場合）エラーを無視
                guard self.isListening else { return }
                self.sendError(code: "RECOGNITION_ERROR", message: "音声認識中にエラーが発生しました")
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

                // iOS の約60秒制限対策: isFinal を受けたら認識タスクだけ再作成
                if self.isListening {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        self?.rotateRecognitionTaskIfNeeded()
                    }
                }
            } else {
                self.sendEvent(type: "onPartialResult",
                               data: ["text": text, "confidence": confidence])
            }
        }
    }

    @discardableResult
    private func createRecognitionRequest() -> Bool {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return false }

        recognitionRequest.shouldReportPartialResults = true
        if #available(iOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        return true
    }

    /// 既存タスクだけをローテーションして、入力タップと AudioEngine は維持する
    private func rotateRecognitionTaskIfNeeded() {
        guard isListening else { return }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            sendError(code: "RECOGNIZER_NOT_AVAILABLE", message: "音声認識が一時的に利用できません")
            stopCurrentSession()
            return
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        guard createRecognitionRequest() else {
            sendError(code: "REQUEST_INIT_ERROR", message: "認識リクエストを作成できませんでした")
            stopCurrentSession()
            return
        }
        startRecognitionTask(with: recognizer)
    }

    private func installInputTap() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        if hasInstalledTap {
            inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            [weak self] buffer, _ in
            guard let self = self else { return }

            self.recognitionRequest?.append(buffer)

            let level = self.calculateRMSLevel(buffer: buffer)
            self.handleAudioLevel(level)
        }
        hasInstalledTap = true
    }

    private func stopCurrentSession() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // ここは復旧不能ではないため黙って継続
        }
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
