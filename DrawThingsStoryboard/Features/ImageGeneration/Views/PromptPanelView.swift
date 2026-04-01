import SwiftUI

/// Left panel: prompt input and generation controls.
struct PromptPanelView: View {

    @ObservedObject var viewModel: ImageGenerationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Prompt").font(.headline)
                TextEditor(text: $viewModel.prompt)
                    .font(.body)
                    .frame(minHeight: 80)
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5))
                    .accessibilityLabel("Prompt")
                    .accessibilityHint("Describe what to generate")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Negative Prompt").font(.headline)
                TextEditor(text: $viewModel.negativePrompt)
                    .font(.body)
                    .frame(minHeight: 50)
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5))
                    .accessibilityLabel("Negative Prompt")
                    .accessibilityHint("Describe what to avoid in the generated image")
            }

            Divider()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Steps: \(viewModel.steps)").font(.caption).foregroundStyle(.secondary)
                    Slider(value: Binding(
                        get: { Double(viewModel.steps) },
                        set: { viewModel.steps = Int($0) }
                    ), in: 1...50, step: 1)
                    .accessibilityLabel("Steps")
                    .accessibilityValue("\(viewModel.steps)")
                    .accessibilityHint("Number of diffusion steps, 1 to 50")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("CFG: \(viewModel.guidanceScale, specifier: "%.1f")").font(.caption).foregroundStyle(.secondary)
                    Slider(value: $viewModel.guidanceScale, in: 1...20, step: 0.5)
                        .accessibilityLabel("Guidance Scale")
                        .accessibilityValue(String(format: "%.1f", viewModel.guidanceScale))
                        .accessibilityHint("Prompt adherence strength, 1 to 20")
                }
            }

            Spacer()

            Button(action: { Task { await viewModel.generate() } }) {
                Group {
                    if viewModel.isGenerating {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("Generating\u{2026}")
                        }
                    } else {
                        Text("Generate")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isGenerating || viewModel.prompt.isEmpty)
            .keyboardShortcut(.return, modifiers: .command)
            .accessibilityLabel(viewModel.isGenerating ? "Generating image" : "Generate")
            .accessibilityHint(viewModel.isGenerating ? "Generation in progress" : "Starts image generation. Keyboard shortcut: Command Return")

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Error: \(error)")
            }
        }
        .padding()
    }
}
