import Foundation
import Speech
import SwiftSignalKit

public struct ExteraSpeechTranscription: Equatable {
    public let text: String
    public let localeIdentifier: String
}

private let recognizerCacheLock = NSLock()
private var recognizerCache: [String: SFSpeechRecognizer] = [:]
private let temporaryCopyQueue = Queue(name: "extera-speech-copy")

private func recognitionRecognizer(localeIdentifier: String) -> SFSpeechRecognizer? {
    recognizerCacheLock.lock()
    defer { recognizerCacheLock.unlock() }

    if let cached = recognizerCache[localeIdentifier], cached.isAvailable {
        return cached
    }
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)), recognizer.isAvailable else {
        return nil
    }
    recognizer.defaultTaskHint = .dictation
    recognizer.supportsOnDeviceRecognition = true
    recognizerCache[localeIdentifier] = recognizer
    return recognizer
}

private final class TranscriptionDispositionState {
    private let lock = NSLock()
    private var disposed = false
    private var pendingCleanup: (() -> Void)?

    var isDisposed: Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.disposed
    }

    func dispose() {
        self.lock.lock()
        self.disposed = true
        let cleanup = self.pendingCleanup
        self.pendingCleanup = nil
        self.lock.unlock()
        cleanup?()
    }

    func recordPendingCleanup(_ cleanup: @escaping () -> Void) {
        self.lock.lock()
        if self.disposed {
            self.lock.unlock()
            cleanup()
            return
        }
        self.pendingCleanup = cleanup
        self.lock.unlock()
    }
}

/// Runs a one-shot offline transcription of an already-decoded audio file through the
/// system Speech framework.
///
/// `nil` means "nothing recognized", not a transient failure — every failure mode is
/// terminal for this short clip, so callers render the same empty-result state for it.
public func transcribeAudioFileOffline(path: String, localeIdentifier: String) -> Signal<ExteraSpeechTranscription?, NoError> {
    return Signal { subscriber in
        let dispositionState = TranscriptionDispositionState()

        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized, !dispositionState.isDisposed else {
                Queue.mainQueue().async {
                    subscriber.putNext(nil)
                    subscriber.putCompletion()
                }
                return
            }

            temporaryCopyQueue.async {
                guard !dispositionState.isDisposed else {
                    return
                }

                guard let recognizer = recognitionRecognizer(localeIdentifier: localeIdentifier) else {
                    Queue.mainQueue().async {
                        subscriber.putNext(nil)
                        subscriber.putCompletion()
                    }
                    return
                }

                // The recognition request keeps reading the file in the background, so it
                // cannot transcribe straight out of the media box, where the resource may be
                // evicted or reused while decoding runs.
                let copiedPath = NSTemporaryDirectory() + "/\(UInt64.random(in: 0 ... UInt64.max)).m4a"
                do {
                    if FileManager.default.fileExists(atPath: copiedPath) {
                        try FileManager.default.removeItem(atPath: copiedPath)
                    }
                    try FileManager.default.copyItem(atPath: path, toPath: copiedPath)
                } catch {
                    Queue.mainQueue().async {
                        subscriber.putNext(nil)
                        subscriber.putCompletion()
                    }
                    return
                }

                let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: copiedPath))
                if #available(iOS 16.0, *) {
                    request.addsPunctuation = true
                }
                request.shouldReportPartialResults = false
                request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition

                let task = recognizer.recognitionTask(with: request, resultHandler: { result, _ in
                    if let result = result, result.isFinal {
                        subscriber.putNext(ExteraSpeechTranscription(text: result.bestTranscription.formattedString, localeIdentifier: localeIdentifier))
                        subscriber.putCompletion()

                        try? FileManager.default.removeItem(atPath: copiedPath)
                    } else if result == nil {
                        subscriber.putNext(nil)
                        subscriber.putCompletion()

                        try? FileManager.default.removeItem(atPath: copiedPath)
                    }
                })

                dispositionState.recordPendingCleanup({
                    task.cancel()
                    try? FileManager.default.removeItem(atPath: copiedPath)
                })
            }
        }

        return ActionDisposable {
            dispositionState.dispose()
        }
    }
}
