import SwiftUI

// MARK: - LiveSessionView — the ONE real, working feature
//
// Set up a room (name + focus length) and run an actual live countdown timer
// (start / pause / resume / end). Reached from the "Set your lock-in" screen
// in the demo flow ("Create room" → here); finishing routes to the results screen.
//
// Uses Swift Concurrency for the tick (no Combine), per CLAUDE.md.

struct LiveSessionView: View {

    var onFinish: () -> Void   // session ended → go to results
    var onCancel: () -> Void   // backed out before finishing

    private enum Phase { case setup, running }

    @State private var phase: Phase = .setup
    @State private var roomName = "Finals Focus Room"
    @State private var minutes = 25
    @State private var useQuickDemo = false

    @State private var remaining = 0      // seconds
    @State private var total = 1          // seconds (for progress)
    @State private var running = false

    private var clock: String { String(format: "%d:%02d", remaining / 60, remaining % 60) }
    private var progress: Double { total > 0 ? Double(total - remaining) / Double(total) : 0 }

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()
            switch phase {
            case .setup:   setupView
            case .running: runningView
            }
        }
        .statusBarHidden(true)
        .task {
            // One long-lived ticker; decrements only while running.
            while true {
                try? await Task.sleep(for: .seconds(1))
                if running && remaining > 0 {
                    remaining -= 1
                    if remaining == 0 { running = false; onFinish() }
                }
            }
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack {
                Button { onCancel() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.Colour.textSecondary)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Set up your room")
                    .font(Theme.TypeScale.largeTitle).foregroundStyle(Theme.Colour.textPrimary)
                Text("Name it and choose how long you'll lock in.")
                    .font(Theme.TypeScale.body).foregroundStyle(Theme.Colour.textSecondary)
            }

            card {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("ROOM NAME").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textSecondary)
                    TextField("Room name", text: $roomName)
                        .font(Theme.TypeScale.headline)
                        .foregroundStyle(Theme.Colour.textPrimary)
                        .textFieldStyle(.plain)
                }
            }

            card {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("FOCUS LENGTH").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textSecondary)
                    Stepper(value: $minutes, in: 1...120, step: 5) {
                        Text("\(minutes) min")
                            .font(Theme.TypeScale.title2).foregroundStyle(Theme.Colour.textPrimary)
                    }
                    Toggle(isOn: $useQuickDemo) {
                        Text("Quick demo (20s)").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                    }
                    .tint(Theme.Colour.accent)
                }
            }

            Spacer()

            primaryButton("Create room & start") {
                total = useQuickDemo ? 20 : minutes * 60
                remaining = total
                running = true
                withAnimation { phase = .running }
            }
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Running

    private var runningView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Text(roomName)
                .font(Theme.TypeScale.title2).foregroundStyle(Theme.Colour.textPrimary)
            Text(running ? "Locked in — focus together." : "Paused")
                .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)

            ZStack {
                Circle()
                    .stroke(Theme.Colour.cardBorder, lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.Colour.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: progress)
                Text(clock)
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.Colour.textPrimary)
            }
            .frame(width: 260, height: 260)
            .padding(.vertical, Theme.Spacing.lg)

            // Pause / Resume
            Button {
                running.toggle()
            } label: {
                Label(running ? "Pause" : "Resume", systemImage: running ? "pause.fill" : "play.fill")
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colour.buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
            }

            Spacer()

            Button("End session") { running = false; onFinish() }
                .font(Theme.TypeScale.caption)
                .foregroundStyle(Theme.Colour.forfeitRed)
                .padding(.bottom, Theme.Spacing.xl)
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Bits

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
    }

    private func primaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.TypeScale.headline)
                .foregroundStyle(Theme.Colour.buttonText)
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Colour.buttonFill)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
        }
    }
}

#Preview {
    LiveSessionView(onFinish: {}, onCancel: {})
}
