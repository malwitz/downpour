import Foundation

enum DownloadKind: String, CaseIterable, Identifiable {
    case video = "Video"
    case audio = "Audio"

    var id: Self { self }
    var symbol: String { self == .video ? "play.rectangle.fill" : "waveform" }
}

enum VideoQuality: String, CaseIterable, Identifiable {
    case best = "Best"
    case p1080 = "1080p"
    case p720 = "720p"
    case p480 = "480p"

    var id: Self { self }

    var height: Int? {
        switch self {
        case .best: nil
        case .p1080: 1080
        case .p720: 720
        case .p480: 480
        }
    }
}

enum DownloadState: Equatable {
    case ready
    case downloading
    case finished
    case failed(String)

    var isDownloading: Bool { self == .downloading }
}

enum DownloadValidation {
    static func normalizedYouTubeURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = url.host?.lowercased() else { return nil }

        let allowedHosts = [
            "youtube.com", "www.youtube.com", "m.youtube.com",
            "music.youtube.com", "youtu.be"
        ]
        guard allowedHosts.contains(host) else { return nil }
        return url
    }
}

enum ProgressParser {
    static func fraction(from line: String) -> Double? {
        guard let range = line.range(of: #"(?:download:)?\s*([0-9]+(?:\.[0-9]+)?)%"#,
                                     options: .regularExpression) else { return nil }
        let match = String(line[range])
        guard let numberRange = match.range(of: #"[0-9]+(?:\.[0-9]+)?"#,
                                            options: .regularExpression),
              let percent = Double(match[numberRange]) else { return nil }
        return min(max(percent / 100, 0), 1)
    }
}

enum YTDLPFormat {
    /// Prefer codecs supported natively by QuickTime: H.264 video and AAC in M4A.
    static func quickTimeVideo(quality: VideoQuality) -> String {
        let heightFilter = quality.height.map { "[height<=\($0)]" } ?? ""
        return "bestvideo[vcodec^=avc1]\(heightFilter)+bestaudio[acodec^=mp4a]/best[vcodec^=avc1][acodec^=mp4a][ext=mp4]\(heightFilter)"
    }
}
