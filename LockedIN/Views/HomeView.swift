import SwiftUI

// MARK: - HomeView — post-onboarding landing
//
// Offers the room choices: £5 Serious Lock-In (working staked loop), Study solo,
// and Join a room (live group). Clean cream layout, proportioned with spacing.

struct HomeView: View {

    enum Destination: Identifiable {
        case lockIn, solo, group, world
        var id: Int { hashValue }
    }

    @Environment(AppStore.self) private var appStore
    @State private var destination: Destination?

    private var name: String {
        appStore.displayName.isEmpty ? "You" : appStore.displayName
    }

    var body: some View {
        ZStack {
            Theme.Colour.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {

                    // Greeting + world chip
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Hi, \(name).")
                                .font(Theme.TypeScale.largeTitle)
                                .foregroundStyle(Theme.Colour.textPrimary)
                            Text("How do you want to study?")
                                .font(Theme.TypeScale.body)
                                .foregroundStyle(Theme.Colour.textSecondary)
                        }
                        Spacer()
                        worldChip
                    }
                    .padding(.top, Theme.Spacing.md)

                    // Featured staked room (the working loop)
                    Button { destination = .lockIn } label: {
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            HStack(spacing: Theme.Spacing.sm) {
                                iconChip("lock.fill")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("£5 Serious Lock-In")
                                        .font(Theme.TypeScale.title2)
                                        .foregroundStyle(Theme.Colour.textPrimary)
                                    Text("Stake £5 · 25 min · with Maya, Leo & Sam")
                                        .font(Theme.TypeScale.caption)
                                        .foregroundStyle(Theme.Colour.textSecondary)
                                }
                                Spacer()
                                chevron
                            }
                            HStack(spacing: Theme.Spacing.sm) {
                                Text("Stake").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                                MoneyLabel(500, compact: true)
                                Spacer()
                                Text("Forfeit → ❤️ British Red Cross")
                                    .font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
                            }
                        }
                        .modifier(CardStyle())
                    }
                    .buttonStyle(.plain)

                    Text("Or just study")
                        .font(Theme.TypeScale.captionBold)
                        .foregroundStyle(Theme.Colour.textSecondary)

                    // Solo + Join row
                    HStack(spacing: Theme.Spacing.md) {
                        optionTile("Study solo", "Your own focus room", "person.fill") { destination = .solo }
                        optionTile("Join a room", "Study with a squad", "person.3.fill") { destination = .group }
                    }

                    Spacer(minLength: Theme.Spacing.xl)

                    Text("TEST MODE — NO REAL MONEY WILL MOVE")
                        .font(Theme.TypeScale.caption)
                        .foregroundStyle(Theme.Colour.testBadgeFg)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(item: $destination) { dest in
            switch dest {
            case .lockIn: RoomFlowView().environment(appStore)
            case .solo:   SoloRoomView().environment(appStore)
            case .group:  GroupRoomView().environment(appStore)
            case .world:  WorldView().environment(appStore)
            }
        }
    }

    // MARK: - Bits

    private var worldChip: some View {
        let p = appStore.world.state.progression
        return Button { destination = .world } label: {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "globe.europe.africa.fill")
                        .font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.Colour.accentTeal)
                    Text("Lv \(p.level)").font(Theme.TypeScale.captionBold).foregroundStyle(Theme.Colour.textPrimary)
                }
                HStack(spacing: 3) {
                    Image(systemName: "circle.fill").font(.system(size: 8)).foregroundStyle(Theme.Colour.accent)
                    Text("\(p.coins)").font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary).monospacedDigit()
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func iconChip(_ symbol: String) -> some View {
        ZStack {
            Circle().fill(Theme.Colour.accent.opacity(0.25)).frame(width: 52, height: 52)
            Image(systemName: symbol).font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.Colour.accent)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").foregroundStyle(Theme.Colour.textSecondary)
    }

    private func optionTile(_ title: String, _ subtitle: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                iconChip(symbol)
                Text(title).font(Theme.TypeScale.headline).foregroundStyle(Theme.Colour.textPrimary)
                Text(subtitle).font(Theme.TypeScale.caption).foregroundStyle(Theme.Colour.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .modifier(CardStyle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card style

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colour.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(Theme.Colour.cardBorder, lineWidth: 1))
    }
}

#Preview("HomeView") {
    HomeView().environment(AppStore())
}
