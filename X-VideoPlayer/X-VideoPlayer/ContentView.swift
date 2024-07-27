//
//  ContentView.swift
//  X-VideoPlayer
//
//  Created by rodgers magabo on 27/07/2024.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @ObservedObject var viewModel = VideoViewModel()
    // State for full-screen mode and the currently selected video
    @State private var isFullScreen = false
    @State private var selectedVideo: Video?
    @State private var player = AVPlayer()
    @State private var playerTime: CMTime = .zero
    
    var body: some View {
        NavigationStack{
            ScrollView(.vertical) {
                LazyVStack {
                    ForEach(viewModel.videos) { video in
                        VStack(alignment: .leading, spacing: 10) {
                         
                                VideoCell(video: video, player: $player, isFullScreen: $isFullScreen, selectedVideo: $selectedVideo)
                                  
                            VStack(alignment: .leading) {
                                    Text(video.user.name)
                                        .font(.subheadline)
                                    Text(video.url)
                                        .font(.caption)

                                }
                                    
                     
                     
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("X - Video player ")
            .navigationBarTitleDisplayMode(.inline)
            .heroFullScreenCover(show: $isFullScreen) {
                if let video = selectedVideo {
                    FeedCell(video: video, player: $player, isFullScreen: $isFullScreen, playerTime: $playerTime)
                }
            }
            .onAppear {
                viewModel.fetchVideos()
            }
        }
    }
}

#Preview {
    ContentView()
}

// Data Models
// Root response model to match the JSON structure
struct VideoResponse: Codable {
    let page: Int
    let per_page: Int
    let total_results: Int
    let videos: [Video]
}

struct Video: Codable, Identifiable {
    let id: Int
    let width: Int
    let height: Int
    let url: String
    let image: String
    let duration: Int
    let user: User
    let video_files: [VideoFile]
    let video_pictures: [VideoPicture]
}

struct User: Codable {
    let id: Int
    let name: String
    let url: String
}

struct VideoFile: Codable, Identifiable {
    let id: Int
    let quality: String
    let file_type: String
    let width: Int
    let height: Int
    let fps: Double
    let link: String
}

struct VideoPicture: Codable, Identifiable {
    let id: Int
    let picture: String
    let nr: Int
}

// ViewModel to handle fetching data
class VideoViewModel: ObservableObject {
    @Published var videos: [Video] = []
    private let apiKey = "e0ovpfuqi7NS5i7gyyuVWVe0VLgjEJIYMnnCtrLmAWzzlGrKONzBzfTB"

    func fetchVideos() {
        guard let url = URL(string: "https://api.pexels.com/videos/search?query=nature&per_page=15") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(VideoResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.videos = decodedResponse.videos
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            } else if let error = error {
                print("Network error: \(error)")
            }
        }.resume()
    }
}


struct VideoPickerTransferable: Transferable {
    let videoURL: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exportingFile in
            return .init(exportingFile.videoURL)
        } importing: { receivedTransferredFile in
            let originalFile = receivedTransferredFile.file
            let copiedFile = URL.documentsDirectory.appending(path: "videoPicker.mov")
            
            if FileManager.default.fileExists(atPath: copiedFile.path()) {
                try FileManager.default.removeItem(at: copiedFile)
            }
            
            try FileManager.default.copyItem(at: originalFile, to: copiedFile)
            return .init(videoURL: copiedFile)
        }
    }
}

struct ImagePickerTransferable: Transferable {
    let image: UIImage
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            return ImagePickerTransferable(image: uiImage)
        }
    }
    
    enum TransferError: Error {
        case importFailed
    }
}

struct FullScreenPlayer: UIViewControllerRepresentable {
    var player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.entersFullScreenWhenPlaybackBegins = true
//        playerViewController.exitsFullScreenWhenPlaybackEnds = true
//        playerViewController.allowsPictureInPicturePlayback = true
//        playerViewController.showsPlaybackControls = false
        playerViewController.allowsVideoFrameAnalysis = false
//        playerViewController.videoGravity = .resizeAspectFill
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
//        uiViewController.player = player
    }
}

struct PreviewScreenVideoPlayer: UIViewControllerRepresentable {
    
    
    var player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
//        playerViewController.entersFullScreenWhenPlaybackBegins = true
//        playerViewController.exitsFullScreenWhenPlaybackEnds = true
//        playerViewController.allowsPictureInPicturePlayback = true
        
        playerViewController.showsPlaybackControls = false
        playerViewController.videoGravity = .resizeAspectFill
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
//        uiViewController.player = player
    }
    
   


    
}



extension View {
    @ViewBuilder
    func heroFullScreenCover<Content: View>(show: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        self
            .modifier(HelperHeroView(show: show, overlay: content()))
    }
}

fileprivate struct HelperHeroView<Overlay: View>: ViewModifier {
    @Binding var show: Bool
    var overlay: Overlay
    @State private var hostView: CustomHostingView<Overlay>?
    @State private var parentController: UIViewController?
    
    func body(content: Content) -> some View {
        content
            .background {
                ExtractSwiftUIParentController(content: overlay, hostView: $hostView) { viewController in
                    parentController = viewController
                }
            }
            .onAppear {
                hostView = CustomHostingView(rootView: overlay, show: $show)
            }
            .onChange(of: show) { _, newValue in
                if newValue {
                    if let hostView {
                        hostView.modalPresentationStyle = .overFullScreen
                        hostView.modalTransitionStyle = .crossDissolve
                        hostView.view.backgroundColor = .clear
                        parentController?.present(hostView, animated: false)
                    }
                } else {
                    hostView?.dismiss(animated: false)
                }
            }
    }
}

fileprivate struct ExtractSwiftUIParentController<Content: View>: UIViewRepresentable {
    var content: Content
    @Binding var hostView: CustomHostingView<Content>?
    var parentController: (UIViewController?) -> ()
    
    func makeUIView(context: Context) -> UIView {
        return UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        hostView?.rootView = content
        DispatchQueue.main.async {
            parentController(uiView.superview?.superview?.parentController)
        }
    }
}

class CustomHostingView<Content: View>: UIHostingController<Content> {
    @Binding var show: Bool
    
    init(rootView: Content, show: Binding<Bool>) {
        self._show = show
        super.init(rootView: rootView)
    }
    
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(false)
        show = false
    }
}

extension UIView {
    var parentController: UIViewController? {
        var responder = self.next
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
}


struct VideoCell: View {
    let video: Video
    @Binding var player: AVPlayer
    @Binding var isFullScreen: Bool
    @Binding var selectedVideo: Video?
    @ObservedObject var viewModel = VideoViewModel()
    
    @State private var playerTime: CMTime = .zero
    
    var body: some View {
        Button {
            selectedVideo = video
            playerTime = player.currentTime()
            isFullScreen = true
        } label: {
            VStack {

                VideoPreview(player: $player, video: video, height: 300)
            }
                
            
            }
        .buttonStyle(.plain)
            
        }
        
    }


struct FeedCell: View {
    @Environment(\.dismiss) var dismiss
    let video: Video
    @Binding var player: AVPlayer
    @Binding var isFullScreen: Bool
    @Binding var playerTime: CMTime
    

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            FullScreenPlayer(player: player)
                .containerRelativeFrame([.horizontal, .vertical])
            
            VStack {
                HStack {
                    Button(action: {
                        isFullScreen = false
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                            .padding()
                            .background(.clear)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                
                Spacer()
            }
        }
        .onAppear {
            player.seek(to: playerTime)
            player.play()
        }
        .onDisappear {
            playerTime = player.currentTime()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 50 {
                        isFullScreen = false
                        dismiss()
                    }
                }
        )
    }
}

struct VideoPreview: View {
    @Binding var player: AVPlayer
    var video: Video
    var height: CGFloat?

    @State private var isMuted: Bool = false
    @State private var videoTime: String = ""
    @State private var timeObserverToken: Any? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                PreviewScreenVideoPlayer(player: player)
                    .onAppear {
                        if let link = video.video_files.first?.link, let url = URL(string: link) {
                            let item = AVPlayerItem(url: url)
                            player.replaceCurrentItem(with: item)
                            player.play()
                            addPeriodicTimeObserver()
                        } else {
                            print("Invalid URL or link is nil")
                        }
                    }
                    .onDisappear {
                        player.pause()
                        removePeriodicTimeObserver()
                    }
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: height ?? 350)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                HStack {
                    Text(videoTime)
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .opacity(videoTime.isEmpty ? 0 : 1)
                    
                    Spacer()
                    
                    Button(action: toggleMute) {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                }
                .padding()
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(height: height ?? 350)
    }
    
    private func toggleMute() {
        isMuted.toggle()
        player.isMuted = isMuted
    }

    private func addPeriodicTimeObserver() {
        removePeriodicTimeObserver()
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            updateVideoTime(currentTime: time)
        }
    }

    private func updateVideoTime(currentTime: CMTime) {
        if let duration = player.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let currentSeconds = CMTimeGetSeconds(currentTime)
            let remainingSeconds = totalSeconds - currentSeconds
            if remainingSeconds > 0 && !remainingSeconds.isNaN && !remainingSeconds.isInfinite {
                videoTime = formatTime(seconds: remainingSeconds)
            } else {
                videoTime = "00:00"
            }
        } else {
            videoTime = "00:00"
        }
    }

    private func removePeriodicTimeObserver() {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    private func formatTime(seconds: Double) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        } else if mins > 0 {
            return String(format: "%02d:%02d", mins, secs)
        } else {
            return String(format: "%02d", secs)
        }
    }
}


