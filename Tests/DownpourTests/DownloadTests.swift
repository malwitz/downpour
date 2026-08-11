import Testing
@testable import Downpour

@Test func acceptsYouTubeURLs() {
    #expect(DownloadValidation.normalizedYouTubeURL(from: "https://youtube.com/watch?v=abc") != nil)
    #expect(DownloadValidation.normalizedYouTubeURL(from: "https://youtu.be/abc") != nil)
    #expect(DownloadValidation.normalizedYouTubeURL(from: " https://music.youtube.com/watch?v=abc \n") != nil)
}

@Test func rejectsNonYouTubeAndMalformedURLs() {
    #expect(DownloadValidation.normalizedYouTubeURL(from: "https://example.com/watch?v=abc") == nil)
    #expect(DownloadValidation.normalizedYouTubeURL(from: "youtube.com/watch?v=abc") == nil)
    #expect(DownloadValidation.normalizedYouTubeURL(from: "") == nil)
}

@Test func parsesDownloaderProgress() {
    #expect(ProgressParser.fraction(from: "download: 42.3%") == 0.423)
    #expect(ProgressParser.fraction(from: "[download] 100% of 12MiB") == 1)
    #expect(ProgressParser.fraction(from: "Preparing download") == nil)
}

@Test func videoFormatIsQuickTimeCompatible() {
    let best = YTDLPFormat.quickTimeVideo(quality: .best)
    let capped = YTDLPFormat.quickTimeVideo(quality: .p720)

    #expect(best.contains("vcodec^=avc1"))
    #expect(best.contains("bestaudio[acodec^=mp4a]"))
    #expect(!best.contains("/best[ext=mp4]"))
    #expect(capped.contains("[height<=720]"))
}
