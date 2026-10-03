import SwiftUI

/// Shared setup keeps solo and demo-room commitments consistent.
struct StudySetupView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title2) private var previewTitleSize = 24.0
    @Binding var config: RoomConfig
    @Binding var clubSize: Int
    var group = false
    let onStart: () -> Void
    let onClose: () -> Void
    @FocusState private var editing: Field?
    private enum Field { case subject, goal }

    private var ready: Bool {
        !config.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !config.goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var roster: [SessionParticipant] {
        SessionParticipant.makeRoster(userCharacter: appStore.userStudyCharacter,
                                      userName: appStore.displayName, config: config, count: clubSize)
    }

    var body: some View {
        VStack(spacing: 0) {
            StudioHeader(title: group ? "The study club" : "Make a little time",
                         subtitle: group ? "Demo room · simulated companions" : "Your personal focus session", close: onClose)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    if group { clubPreview } else { soloPreview }
                    VStack(alignment: .leading, spacing: 14) {
                        planHeading("01", "Give this session a purpose", "One subject. One achievable goal.")
                        VStack(alignment: .leading, spacing: 8) {
                            Label("SUBJECT", systemImage: "book.closed").font(.caption2.weight(.bold)).tracking(1)
                            TextField("e.g. Biology", text: $config.subject)
                                .accessibilityIdentifier("study.subject")
                                .accessibilityLabel("Subject")
                                .accessibilityHint("Up to 40 characters")
                                .textInputAutocapitalization(.sentences)
                                .focused($editing, equals: .subject)
                                .submitLabel(.next)
                                .onSubmit { editing = .goal }
                                .onChange(of: config.subject) { _, text in config.subject = cleanStudyText(text, limit: 40) }
                            Divider().overlay(Theme.Colour.cardBorder.opacity(0.4)).padding(.vertical, 8)
                            Label("ONE SMALL GOAL", systemImage: "scope").font(.caption2.weight(.bold)).tracking(1)
                            TextField("e.g. Finish my notes on chapter 4", text: $config.goal, axis: .vertical)
                                .accessibilityIdentifier("study.goal")
                                .accessibilityLabel("One small goal")
                                .accessibilityHint("Up to 120 characters")
                                .textInputAutocapitalization(.sentences)
                                .lineLimit(2...3)
                                .focused($editing, equals: .goal)
                                .onChange(of: config.goal) { _, text in config.goal = cleanStudyText(text, limit: 120) }
                        }
                        .font(.subheadline)
                        .padding(18)
                        .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.Colour.cardBorder.opacity(0.6)))
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        planHeading("02", "Choose your pace", "Time to settle in, with room for a break.")
                        durationLayout {
                            duration(25, "A little sprint")
                            duration(50, "Settle in")
                            duration(90, "Go deeper")
                        }
                    }
                    if !ready {
                        Text("Add a subject and a small goal to start your session.")
                            .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "leaf").font(.system(size: 20)).foregroundStyle(Theme.Colour.focusGreen)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Your session, at a glance").font(.subheadline.weight(.semibold))
                            Text("\(config.focusMinutes) minutes · one flexible break\nA private check-in when you finish.")
                                .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                        }
                    }.modifier(StudioCard())
                    Text(group ? "All companions and their study goals are simulated. Private invites and real multiplayer are still being built." : "This version offers a focus timer and self-reported breaks. It does not block other apps.")
                        .font(.caption).foregroundStyle(Theme.Colour.textSecondary).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(Theme.Colour.textPrimary)
        .background(Theme.Colour.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                editing = nil
                config.subject = config.subject.trimmingCharacters(in: .whitespacesAndNewlines)
                config.goal = config.goal.trimmingCharacters(in: .whitespacesAndNewlines)
                onStart()
            } label: {
                HStack {
                    Text(group ? "Join & focus" : "Let’s focus")
                    Spacer()
                    Text("\(config.focusMinutes) min").font(.subheadline.weight(.regular))
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(StudioButtonStyle(primary: true))
            .accessibilityIdentifier("study.begin")
            .disabled(!ready)
            .padding(.horizontal, 24).padding(.vertical, 12)
            .background(Theme.Colour.background)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { editing = nil }
            }
        }
    }

    private var durationLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 10))
            : AnyLayout(HStackLayout(spacing: 10))
    }

    private var previewLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(spacing: 16))
    }

    private var soloPreview: some View {
        previewLayout {
            PixelAvatarView(appearance: appStore.userCharacter, status: .idle, size: 94)
                .frame(width: 88, height: 110)
                .background(Theme.Colour.surfaceMid.opacity(0.65), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                StudioEyebrow(text: "A room for you")
                Text(dynamicTypeSize.isAccessibilitySize ? "Leave a little space to focus." : "Leave a little\nspace to focus.")
                    .font(.system(size: previewTitleSize, weight: .bold, design: .rounded)).tracking(-0.5)
                Text("Your outfit. Your room. Your pace.")
                    .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.Colour.cardBorder))
    }

    private var clubPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            previewLayout {
                HStack(spacing: -10) {
                    ForEach(Array(roster.prefix(4))) { person in
                        SpriteAvatarView(character: person.character, status: .idle, size: 52, showStatusBadge: false)
                            .frame(width: 42, height: 62)
                    }
                }
                .accessibilityHidden(true)
                Spacer(minLength: 0)
                VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 5) {
                    Text("Study, together.").font(.system(.headline, design: .rounded))
                    Text("A cosy club to try out")
                        .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                }
            }
            Rectangle().fill(Theme.Colour.cardBorder.opacity(0.6)).frame(height: 1)
            previewLayout {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(clubSize) study seats").font(.subheadline.weight(.semibold))
                        .accessibilityIdentifier("study.clubSize")
                    Text("You + \(clubSize - 1) demo companions")
                        .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
                }
                Spacer(minLength: 0)
                HStack(spacing: 10) {
                    seatButton("minus", enabled: clubSize > 2, identifier: "study.clubSize.decrease", label: "Fewer study seats") { clubSize = max(2, clubSize - 1) }
                    Text("\(clubSize)").font(.system(.headline, design: .monospaced, weight: .semibold)).frame(minWidth: 20)
                        .accessibilityHidden(true)
                    seatButton("plus", enabled: clubSize < 8, identifier: "study.clubSize.increase", label: "More study seats") { clubSize = min(8, clubSize + 1) }
                }
            }
            Text("Subjects and goals appear in the club. Your check-in afterwards stays private.")
                .font(.caption).foregroundStyle(Theme.Colour.textSecondary)
        }.modifier(StudioCard())
    }

    private func seatButton(_ symbol: String, enabled: Bool, identifier: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 14, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Theme.Colour.surfaceMid.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colour.cardBorder))
        }.buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1 : 0.35)
            .accessibilityLabel(label).accessibilityValue("\(clubSize) seats")
            .accessibilityIdentifier(identifier)
    }

    private func planHeading(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 10) {
            Text(number).font(.system(size: 11, weight: .bold, design: .monospaced))
                .frame(width: 30, height: 30)
                .background(Theme.Colour.surfaceMid, in: RoundedRectangle(cornerRadius: 9))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                Text(detail).font(.caption).foregroundStyle(Theme.Colour.textSecondary)
            }
        }
    }

    private func cleanStudyText(_ text: String, limit: Int) -> String {
        String(String(text.unicodeScalars.map {
            CharacterSet.controlCharacters.contains($0) ? " " : String($0)
        }.joined()).prefix(limit))
    }

    private func duration(_ minutes: Int, _ caption: String) -> some View {
        let selected = config.focusMinutes == minutes
        return Button {
            config.focusMinutes = minutes
            config.quickDemo = false
        } label: {
            VStack(spacing: 6) {
                HStack {
                    Spacer()
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12)).foregroundStyle(selected ? Theme.Colour.testBadgeFg : Theme.Colour.cardBorder)
                }.padding(.horizontal, 10)
                Text("\(minutes)").font(.system(.title2, design: .rounded, weight: .semibold))
                Text("minutes").font(.caption)
                Text(caption).font(.caption2)
            }
            .frame(maxWidth: .infinity).padding(.top, 9).padding(.bottom, 14)
            .foregroundStyle(Theme.Colour.textPrimary)
            .background(selected ? Theme.Colour.accentSoft.opacity(0.45) : Theme.Colour.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(selected ? Theme.Colour.testBadgeFg : Theme.Colour.cardBorder, lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(minutes) minutes, \(caption)")
        .accessibilityValue(selected ? "Selected" : "")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
