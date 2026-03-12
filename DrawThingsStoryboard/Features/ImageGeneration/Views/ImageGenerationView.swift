import SwiftUI

/// Shell view for Image Generation — composes focused sub-views only.
struct ImageGenerationView: View {

    @StateObject private var viewModel = ImageGenerationViewModel()

    var body: some View {
        HSplitView {
            PromptPanelView(viewModel: viewModel)
                .frame(minWidth: 280, maxWidth: 360)

            ImageCanvasView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Image Generation")
    }
}

#Preview {
    ImageGenerationView()
        .frame(width: 900, height: 600)
}
