import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var manager = DownloadManager()
    @FocusState private var isURLFocused: Bool

    private let accent = Color(red: 0.96, green: 0.24, blue: 0.18)

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
            Circle()
                .fill(accent.opacity(0.08))
                .frame(width: 430, height: 430)
                .blur(radius: 30)
                .offset(x: 330, y: -260)

            VStack(spacing: 0) {
                header
                Spacer(minLength: 24)
                mainCard
                Spacer(minLength: 22)
                footer
            }
            .padding(32)
        }
        .tint(accent)
        .onAppear { isURLFocused = true }
        .onChange(of: manager.kind) { newKind in
            if newKind == .audio { manager.quality = .best }
        }
        .onSubmit { if manager.canDownload { manager.startDownload() } }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 42, height: 42)
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
            VStack(alignment: .leading, spacing: 1) {
                Text("Downpour")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("QuickTime-ready • H.264 + AAC")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: manager.revealOutputFolder) {
                Label("Downloads", systemImage: "folder")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
    }

    private var mainCard: some View {
        VStack(spacing: 22) {
            VStack(alignment: .leading, spacing: 9) {
                Text("VIDEO LINK")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Image(systemName: manager.validURL == nil ? "link" : "checkmark.circle.fill")
                        .foregroundStyle(manager.validURL == nil ? Color.secondary : accent)
                    TextField("Paste a YouTube URL", text: $manager.urlText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                        .focused($isURLFocused)
                        .disabled(manager.state.isDownloading)
                    Button("Paste", action: manager.pasteFromClipboard)
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent)
                }
                .padding(.horizontal, 15)
                .frame(height: 48)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isURLFocused ? accent.opacity(0.65) : Color.primary.opacity(0.08), lineWidth: 1)
                }
            }

            HStack(spacing: 14) {
                optionPicker
                qualityPicker
                folderPicker
            }

            if !manager.dependencyStatus.isReady {
                setupNotice
            } else if manager.state.isDownloading || manager.state == .finished {
                progressView
            } else if case let .failed(message) = manager.state {
                failureNotice(message)
            }

            downloadButton
        }
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 24, y: 10)
    }

    private var optionPicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            fieldLabel("FORMAT")
            Picker("Format", selection: $manager.kind) {
                ForEach(DownloadKind.allCases) { item in
                    Label(item.rawValue, systemImage: item.symbol).tag(item)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
    }

    private var qualityPicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            fieldLabel("QUALITY")
            Picker("Quality", selection: $manager.quality) {
                if manager.kind == .audio {
                    Text("Best MP3").tag(VideoQuality.best)
                } else {
                    ForEach(VideoQuality.allCases) { item in Text(item.rawValue).tag(item) }
                }
            }
            .labelsHidden()
            .disabled(manager.kind == .audio)
            .frame(maxWidth: .infinity)
        }
    }

    private var folderPicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            fieldLabel("SAVE TO")
            Button(action: manager.chooseOutputFolder) {
                HStack {
                    Image(systemName: "folder")
                    Text(manager.outputFolder.lastPathComponent)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var setupNotice: some View {
        HStack(spacing: 12) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("One-time setup needed")
                    .font(.system(size: 13, weight: .semibold))
                Text("Install \(manager.dependencyStatus.missingNames) with Homebrew, then reopen Downpour.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Copy command", action: manager.copySetupCommand)
                .buttonStyle(.borderless)
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(13)
        .background(Color.orange.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private var progressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text(manager.statusText)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text("\(Int(manager.progress * 100))%")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: manager.progress)
                .progressViewStyle(.linear)
        }
    }

    private func failureNotice(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("The download didn’t finish")
                    .font(.system(size: 12, weight: .semibold))
                Text(message)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var downloadButton: some View {
        Button {
            manager.state.isDownloading ? manager.cancelDownload() : manager.startDownload()
        } label: {
            HStack(spacing: 8) {
                if manager.state.isDownloading {
                    Image(systemName: "xmark")
                    Text("Cancel")
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                    Text(manager.state == .finished ? "Download another" : "Download")
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 46)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(manager.state.isDownloading ? Color.secondary : accent)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(manager.canDownload || manager.state.isDownloading ? 1 : 0.42)
        .disabled(!manager.canDownload && !manager.state.isDownloading)
    }

    private var footer: some View {
        Text("Only download media you own or have permission to use.")
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold))
            .tracking(1.1)
            .foregroundStyle(.secondary)
    }
}
