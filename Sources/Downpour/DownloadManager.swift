import AppKit
import Foundation

@MainActor
final class DownloadManager: ObservableObject {
    @Published var urlText = ""
    @Published var kind: DownloadKind = .video
    @Published var quality: VideoQuality = .best
    @Published var outputFolder: URL
    @Published private(set) var state: DownloadState = .ready
    @Published private(set) var progress: Double = 0
    @Published private(set) var statusText = "Ready to download"

    private var process: Process?
    private var outputBuffer = ""

    init() {
        outputFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
    }

    var validURL: URL? { DownloadValidation.normalizedYouTubeURL(from: urlText) }
    var canDownload: Bool { validURL != nil && !state.isDownloading && dependencyStatus.isReady }

    var dependencyStatus: DependencyStatus {
        let ytdlp = executable(named: "yt-dlp")
        let ffmpeg = executable(named: "ffmpeg")
        return DependencyStatus(ytdlp: ytdlp, ffmpeg: ffmpeg)
    }

    func pasteFromClipboard() {
        guard let value = NSPasteboard.general.string(forType: .string) else { return }
        urlText = value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose where downloads are saved"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = outputFolder
        if panel.runModal() == .OK, let url = panel.url { outputFolder = url }
    }

    func revealOutputFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([outputFolder])
    }

    func copySetupCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("brew install yt-dlp ffmpeg", forType: .string)
        statusText = "Setup command copied"
    }

    func startDownload() {
        guard let url = validURL, let ytdlp = dependencyStatus.ytdlp else { return }

        progress = 0
        outputBuffer = ""
        state = .downloading
        statusText = "Preparing download…"

        let task = Process()
        let pipe = Pipe()
        task.executableURL = ytdlp
        task.arguments = arguments(for: url)
        task.standardOutput = pipe
        task.standardError = pipe

        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = [
            "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", environment["PATH"] ?? ""
        ].joined(separator: ":")
        task.environment = environment

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in self?.consume(text) }
        }

        task.terminationHandler = { [weak self] completedTask in
            pipe.fileHandleForReading.readabilityHandler = nil
            Task { @MainActor [weak self] in
                self?.finish(exitCode: completedTask.terminationStatus)
            }
        }

        do {
            try task.run()
            process = task
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            state = .failed(error.localizedDescription)
            statusText = "Couldn’t start the downloader"
        }
    }

    func cancelDownload() {
        process?.interrupt()
        process = nil
        state = .ready
        progress = 0
        statusText = "Download cancelled"
    }

    private func arguments(for url: URL) -> [String] {
        var args = [
            "--newline",
            "--no-playlist",
            "--no-overwrites",
            "--progress-template", "download:%(progress._percent_str)s",
            "--paths", outputFolder.path,
            "--output", "%(title).180B.%(ext)s"
        ]

        switch kind {
        case .audio:
            args += ["--extract-audio", "--audio-format", "mp3", "--audio-quality", "0"]
        case .video:
            args += ["--format", YTDLPFormat.quickTimeVideo(quality: quality)]
            args += ["--merge-output-format", "mp4"]
        }

        args.append(url.absoluteString)
        return args
    }

    private func consume(_ text: String) {
        outputBuffer.append(text)
        let lines = outputBuffer.components(separatedBy: .newlines)
        outputBuffer = lines.last ?? ""

        for line in lines.dropLast() {
            if let fraction = ProgressParser.fraction(from: line) {
                progress = fraction
                statusText = "Downloading \(Int(fraction * 100))%"
            } else if line.contains("Merging formats") || line.contains("ExtractAudio") {
                statusText = kind == .audio ? "Creating MP3…" : "Finishing video…"
            }
        }
    }

    private func finish(exitCode: Int32) {
        process = nil
        if exitCode == 0 {
            progress = 1
            state = .finished
            statusText = "Download complete"
            NSSound(named: "Glass")?.play()
        } else if state.isDownloading {
            state = .failed("yt-dlp exited with code \(exitCode)")
            statusText = "Download failed"
        }
    }

    private func executable(named name: String) -> URL? {
        let candidates = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)"
        ]
        return candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }).map(URL.init(fileURLWithPath:))
    }
}

struct DependencyStatus {
    let ytdlp: URL?
    let ffmpeg: URL?

    var isReady: Bool { ytdlp != nil && ffmpeg != nil }
    var missingNames: String {
        [ytdlp == nil ? "yt-dlp" : nil, ffmpeg == nil ? "ffmpeg" : nil]
            .compactMap { $0 }
            .joined(separator: " and ")
    }
}
