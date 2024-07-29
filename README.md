# X-VideoPlayer

This X-VideoPlayer features a video player with a list of videos fetched from an API. The app supports full-screen playback, video previews, and dynamic updating of the currently playing video based on visibility. inspired by the video player from X but still has some minor bugs. 

Features
Video List: Displays a list of videos with user information.
Full-Screen Playback: Tapping a video opens it in full-screen mode with playback controls.
Dynamic Playback: The app determines which video should be playing based on visibility on the screen.
Mute and Play Controls: Users can mute/unmute and play/pause videos.
Key Components
ContentView
The main entry point of the app, managing video state and navigation.

VideoListView
Displays a scrollable list of videos using LazyVStack. It dynamically calculates and updates which video should be playing based on its visibility.

VideoCell
Each cell in the list represents a video. Tapping a cell switches to full-screen playback mode.


VideoPreview
Shows a preview of the video with a playback time display.


PlayerViewModel
Handles video playback state, including loading videos, playing, pausing, and toggling mute.


Video Models
Data models defining the structure of the video, user, and associated video files.


Getting Started
Clone the repository.
Open the project in Xcode.
Build and run the project on your device or simulator.

Dependencies
AVKit and AVFoundation: For video playback.
Combine: For state management.

License and Contribution
This project  is offered as-is and is open for use by any developer. Contributions are welcome—feel free to fork the repository and submit pull requests if you would like to enhance the project.