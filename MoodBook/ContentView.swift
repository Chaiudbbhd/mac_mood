import SwiftUI

struct ContentView: View {
    @StateObject var cameraVM = CameraViewModel()
    @State private var showMood = false
    @State private var pulse = false
    @Namespace private var animation // For smooth transitions

    var body: some View {
        VStack(spacing: 25) {
            Text("🧠 MoodBook")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundColor(.purple)

            if showMood {
                VStack(spacing: 15) {
                    // Mood emoji with smooth animation
                    Text(cameraVM.currentEmoji)
                        .font(.system(size: 100))
                        .foregroundColor(color(for: cameraVM.currentMoodText))
                        .matchedGeometryEffect(id: "emoji", in: animation)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.3), value: cameraVM.currentEmoji)

                    // Mood text label
                    Text(cameraVM.currentMoodText)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(color(for: cameraVM.currentMoodText))
                        .multilineTextAlignment(.center)
                        .matchedGeometryEffect(id: "moodText", in: animation)
                        .transition(.opacity.combined(with: .slide))
                        .animation(.easeInOut(duration: 0.4), value: cameraVM.currentMoodText)

                    // Funny / sarcastic message
                    Text(funnyMessage(for: cameraVM.currentMoodText))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                        .padding()
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity.combined(with: .slide))
                        .animation(.easeInOut(duration: 0.4), value: cameraVM.currentMoodText)
                }
            } else {
                // Initial scanning prompt
                Text("Scanning your vibes… 👀")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.blue)
                    .scaleEffect(pulse ? 1.05 : 0.95)
                    .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
                    .onAppear { pulse = true }
            }
        }
        .padding()
        .background(LinearGradient(colors: [.white, .blue.opacity(0.1)], startPoint: .top, endPoint: .bottom))
        .cornerRadius(25)
        .shadow(radius: 8)
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showMood = true }
            }
        }
    }

    // MARK: - Mood Color
    func color(for mood: String) -> Color {
        switch mood {
        case "Sleepy": return .gray
        case "Happy": return .green
        case "Sad": return .blue
        case "Shock": return .yellow
        case "Laugh": return .orange
        default: return .black
        }
    }

    // MARK: - Funny / sarcastic messages
    func funnyMessage(for mood: String) -> String {
        switch mood {
        case "Sleepy": return "Yawn… maybe take a nap after coding 😴"
        case "Happy": return "Smile bright! Your code looks awesome 😄"
        case "Sad": return "Don't worry, even bugs have debugging days 🐛"
        case "Shock": return "Whoa! Did someone merge a PR without conflicts? 😱"
        case "Laugh": return "Haha! Coding can be fun when it works 😆"
        default: return "Scanning your mood…"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
