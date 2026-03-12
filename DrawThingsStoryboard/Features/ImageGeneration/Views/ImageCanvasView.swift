import SwiftUI

/// Right panel: shows the generated image or a placeholder.
struct ImageCanvasView: View {

    @ObservedObject var viewModel: ImageGenerationViewModel

    var body: some View {
        Group {
            if let image = viewModel.generatedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            } else if viewModel.isGenerating {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Generating image…").foregroundStyle(.secondary)
                }
            } else {
                ContentUnavailableView(
                    "No Image Yet",
                    systemImage: "photo.artframe",
                    description: Text("Enter a prompt and press ⌘↩ to generate.")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .underPageBackgroundColor))
    }
}
