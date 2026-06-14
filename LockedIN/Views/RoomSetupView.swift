import SwiftUI

// MARK: - RoomSetupView — "Set your lock-in" (real commitment contract setup)
//
// The user composes the focus contract before locking in: room name, subject,
// focus length, break allowance, distraction limit, stake (Int pence via MoneyLabel),
// competitive vs supportive mode, and an optional 20s quick-demo timer. The live
// contract summary reflects every change. "Create room" freezes the config and
// hands it to the orchestrator via `onStart`.
//
// Money is Int pence throughout (FND-01); stake capped at the £20 seeded wallet.

struct RoomSetupView: View {

    var onStart: (RoomConfig) -> Void
    var onCancel: () -> Void

    @State private var config: RoomConfig = .preset

    // Stake bounds (pence): £1 … £20 in £1 steps — never exceeds the seeded wallet.
    private let stakeStep: Pence = 100
    private let stakeMin: Pence = 100
    private let stakeMax: Pence = 2000

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        identityCard
                        stakeCard
                        rulesCard
                        modeCard
                        summaryCard
                    }
                    .padding(Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xl)
                }

                footer
            }
        }
        .statusBarHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Button { onCancel() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.Colour.textSecondary)
                }
                Spacer()
            }
            Text("Set your lock-in")
                .font(Theme.TypeScale.largeTitle)
                .foregroundStyle(Theme.Colour.textPrimary)
            Text("Agree the contract, then put your stake on the line.")
                .font(Theme.TypeScale.body)
                .foregroundStyle(Theme.Colour.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Identity (room name + subject)

    private var identityCard: some View {
        card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                fieldLabel("ROOM NAME")
                TextField("Room name", text: $config.roomName)
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.textPrimary)
                    .textFieldStyle(.plain)
                    .onChange(of: config.roomName) { _, new in
                        if new.count > 30 { config.roomName = String(new.prefix(30)) }
                    }

                Divider()

                fieldLabel("SUBJECT")
                TextField("What are you studying?", text: $config.subject)
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.textPrimary)
                    .textFieldStyle(.plain)
                    .onChange(of: config.subject) { _, new in
                        if new.count > 30 { config.subject = String(new.prefix(30)) }
                    }
            }
        }
    }

    // MARK: - Stake

    private var stakeCard: some View {
        card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                fieldLabel("YOUR STAKE")
                HStack(alignment: .center) {
                    MoneyLabel(config.stakePence)
                    Spacer()
                    Stepper("", value: $config.stakePence, in: stakeMin...stakeMax, step: stakeStep)
                        .labelsHidden()
                        .tint(Theme.Colour.accent)
                }
                Text("Forfeit → ❤️ \(config.forfeitDestination)")
                    .font(Theme.TypeScale.caption)
                    .foregroundStyle(Theme.Colour.textSecondary)
            }
        }
    }

    // MARK: - Rules (focus length + breaks + distractions)

    private var rulesCard: some View {
        card {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                stepperRow(
                    "FOCUS LENGTH",
                    value: config.quickDemo ? "20 sec" : "\(config.focusMinutes) min",
                    stepper: Stepper("", value: $config.focusMinutes, in: 5...120, step: 5)
                )
                .opacity(config.quickDemo ? 0.4 : 1)
                .disabled(config.quickDemo)

                Divider()

                stepperRow(
                    "BREAKS ALLOWED",
                    value: "\(config.breakAllowance)",
                    stepper: Stepper("", value: $config.breakAllowance, in: 0...3)
                )

                Divider()

                stepperRow(
                    "DISTRACTION LIMIT",
                    value: "\(config.distractionLimit)",
                    stepper: Stepper("", value: $config.distractionLimit, in: 0...5)
                )
            }
        }
    }

    // MARK: - Mode (competitive / quick demo)

    private var modeCard: some View {
        card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Toggle(isOn: $config.competitive) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(config.competitive ? "Competitive" : "Supportive")
                            .font(Theme.TypeScale.headline)
                            .foregroundStyle(Theme.Colour.textPrimary)
                        Text(config.competitive
                             ? "Crown a Champion and a Biggest Culprit at the reveal."
                             : "Celebrate finishers — no calling out who folded.")
                            .font(Theme.TypeScale.caption)
                            .foregroundStyle(Theme.Colour.textSecondary)
                    }
                }
                .tint(Theme.Colour.accent)

                Divider()

                Toggle(isOn: $config.quickDemo) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quick demo (20s)")
                            .font(Theme.TypeScale.headline)
                            .foregroundStyle(Theme.Colour.textPrimary)
                        Text("Runs the whole loop in 20 seconds for a fast walkthrough.")
                            .font(Theme.TypeScale.caption)
                            .foregroundStyle(Theme.Colour.textSecondary)
                    }
                }
                .tint(Theme.Colour.accent)
            }
        }
    }

    // MARK: - Contract summary

    private var summaryCard: some View {
        card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("THE CONTRACT")
                    .font(Theme.TypeScale.captionBold)
                    .foregroundStyle(Theme.Colour.textSecondary)

                Text("KEEPS YOUR STAKE")
                    .font(Theme.TypeScale.captionBold)
                    .foregroundStyle(Theme.Colour.moneyGreen)
                summaryRow("✓", "Stay focused for \(config.quickDemo ? "20 sec" : "\(config.focusMinutes) min")")
                summaryRow("✓", "Up to \(config.breakAllowance) break\(config.breakAllowance == 1 ? "" : "s")")

                Divider().padding(.vertical, Theme.Spacing.xs)

                Text("FORFEITS YOUR STAKE")
                    .font(Theme.TypeScale.captionBold)
                    .foregroundStyle(Theme.Colour.forfeitRed)
                summaryRow("✗", "Leave early")
                summaryRow("✗", "More than \(config.distractionLimit) distraction\(config.distractionLimit == 1 ? "" : "s")")
            }
        }
    }

    // MARK: - Footer (CTA)

    private var footer: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button { onStart(frozenConfig()) } label: {
                Text("Create room & lock in")
                    .font(Theme.TypeScale.headline)
                    .foregroundStyle(Theme.Colour.buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colour.buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
            }
            Text("TEST MODE — NO REAL MONEY WILL MOVE")
                .font(Theme.TypeScale.caption)
                .foregroundStyle(Theme.Colour.testBadgeFg)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Helpers

    /// Normalises the config before handing it off (trims blank names).
    private func frozenConfig() -> RoomConfig {
        var c = config
        let trimmedRoom = c.roomName.trimmingCharacters(in: .whitespaces)
        c.roomName = trimmedRoom.isEmpty ? "Focus Room" : trimmedRoom
        c.subject = c.subject.trimmingCharacters(in: .whitespaces)
        return c
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.TypeScale.captionBold)
            .foregroundStyle(Theme.Colour.textSecondary)
    }

    private func stepperRow(_ label: String, value: String, stepper: some View) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                fieldLabel(label)
                Text(value)
                    .font(Theme.TypeScale.title2)
                    .foregroundStyle(Theme.Colour.textPrimary)
            }
            Spacer()
            stepper.labelsHidden().tint(Theme.Colour.accent)
        }
    }

    private func summaryRow(_ mark: String, _ text: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(mark).font(Theme.TypeScale.body)
            Text(text).font(Theme.TypeScale.body).foregroundStyle(Theme.Colour.textPrimary)
        }
    }

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
    }
}

#Preview("Room setup") {
    RoomSetupView(onStart: { _ in }, onCancel: {})
        .environment(AppStore())
}
