//
//  ContentView.swift
//  X-VideoPlayer
//
//  Created by rodgers magabo on 27/07/2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = VideoViewModel()
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                ForEach(viewModel.videos) { video in
                    VStack(alignment: .leading) {
                        Text(video.user.name)
                            .font(.headline)
                        Text(video.url)
                            .font(.subheadline)
                        AsyncImage(url: URL(string: video.image))
                            .frame(width: 100, height: 100)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.fetchVideos()
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


