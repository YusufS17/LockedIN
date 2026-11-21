import SwiftUI

/// A concise plan before entering the room. Session rules and roster creation
/// remain owned by the saved study flow.
struct StudySetupView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var config: RoomConfig
    @Binding var clubSize: Int
    var group = false
    let onStart: () -> Void
    let onClose: () -> Void
    @FocusState private var editing: Field?
    @State private var showsDetails = false
    private enum Field { case subject, goal }

    private var ready: Bool {
        !config.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !config.goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left").font(.headline)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                .accessibilityIdentifier("studio.back")
                Text(group ? "Demo study club" : "Start a session")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
            }.padding(.horizontal, 12).padding(.vertical, 8)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        fieldHeading("Subject")
                        TextField("e.g. Biology", text: $config.subject)
                            .accessibilityIdentifier("study.subject")
                            .accessibilityLabel("Subject")
                            .accessibilityHint("Up to 40 characters")
                            .textInputAutocapitalization(.sentences)
                            .focused($editing, equals: .subject)
                            .submitLabel(.next)
                            .onSubmit { editing = .goal }
                            .onChange(of: config.subject) { _, text in config.subject = cleanStudyText(text, limit: 40) }
                            .modifier(FocusInputSurface())
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        fieldHeading("One small goal")
                        TextField("e.g. Finish my notes on chapter 4", text: $config.goal, axis: .vertical)
                            .accessibilityIdentifier("study.goal")
                            .accessibilityLabel("One small goal")
                            .accessibilityHint("Up to 120 characters")
                            .textInputAutocapitalization(.sentences)
                            .lineLimit(2...3)
                            .focused($editing, equals: .goal)
                            .onChange(of: config.goal) { _, text in config.goal = cleanStudyText(text, limit: 120) }
                            .modifier(FocusInputSurface())
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        fieldHeading("Duration")
                        (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 10))) {
                            duration(25, "A little sprint")
                            duration(50, "Settle in")
                            duration(90, "Go deeper")
                        }
                    }
                    if group { seats }
                    if !ready {
                        Text("Add a subject and goal to begin.")
                            .font(.caption).foregroundStyle(FocusApartmentStyle.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Button { showsDetails = true } label: {
                        Label("How focus works", systemImage: "info.circle")
                            .font(.caption).frame(minHeight: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(FocusApartmentStyle.secondary)
                }
                .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(FocusApartmentStyle.ink)
        .background {
            ApartmentNightBackdrop().ignoresSafeArea()
                .overlay(FocusApartmentStyle.background.opacity(0.60))
        }
        .preferredColorScheme(.dark)
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
                    Text("\(config.focusMinutes) min").fontWeight(.regular)
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(FocusApartmentButtonStyle(primary: true))
            .accessibilityIdentifier("study.begin")
            .disabled(!ready)
            .padding(.horizontal, 24).padding(.vertical, 12)
            .background(FocusApartmentStyle.background)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { editing = nil }
            }
        }
        .sheet(isPresented: $showsDetails) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Your timer continues outside the app. Breaks and interruptions are self-reported; other app use is not tracked or blocked.")
                        Text("Take up to \(config.breakAllowance) planned break\(config.breakAllowance == 1 ? "" : "s"). Your goal check-in at the end stays private.")
                        if group { Text("Companions and their study goals are simulated. This is a demo room, not live multiplayer.") }
                    }.font(.body).padding(24)
                }
                .navigationTitle("How focus works").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showsDetails = false } } }
                .foregroundStyle(FocusApartmentStyle.ink)
                .background(FocusApartmentStyle.background)
            }
            .preferredColorScheme(.dark)
        }
    }

    private func fieldHeading(_ text: String) -> some View {
        Text(text).font(.subheadline.weight(.semibold)).accessibilityAddTraits(.isHeader)
    }

    private var seats: some View {
        (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 12))) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(clubSize) study seats").font(.subheadline.weight(.semibold))
                    .accessibilityIdentifier("study.clubSize")
                Text("You + \(clubSize - 1) simulated companions")
                    .font(.caption).foregroundStyle(FocusApartmentStyle.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
            HStack(spacing: 10) {
                seatButton("minus", enabled: clubSize > 2, identifier: "study.clubSize.decrease", label: "Fewer study seats") { clubSize = max(2, clubSize - 1) }
                Text("\(clubSize)").font(.headline.monospacedDigit()).frame(minWidth: 20).accessibilityHidden(true)
                seatButton("plus", enabled: clubSize < 8, identifier: "study.clubSize.increase", label: "More study seats") { clubSize = min(8, clubSize + 1) }
            }
        }
    }

    private func seatButton(_ symbol: String, enabled: Bool, identifier: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.subheadline.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(FocusApartmentStyle.panel, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(FocusApartmentStyle.border))
                .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1 : 0.35)
        .accessibilityLabel(label).accessibilityValue("\(clubSize) seats").accessibilityIdentifier(identifier)
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
            HStack(spacing: 6) {
                Text("\(minutes)").font(.system(.title3, design: .rounded, weight: .bold))
                Text("min").font(.caption)
            }
            .foregroundStyle(selected ? FocusApartmentStyle.buttonInk : FocusApartmentStyle.ink)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(selected ? FocusApartmentStyle.amber : FocusApartmentStyle.panel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? FocusApartmentStyle.amber : FocusApartmentStyle.border))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(minutes) minutes, \(caption)")
        .accessibilityValue(selected ? "Selected" : "")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("study.duration.\(minutes)")
    }
}

private struct FocusInputSurface: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.body).tint(FocusApartmentStyle.amber)
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(FocusApartmentStyle.panel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(FocusApartmentStyle.border))
    }
}

/// Shared only by the setup and live-focus shell; room assets remain independent.
enum FocusApartmentStyle {
    static let background = Color(red: 0.075, green: 0.090, blue: 0.105)
    static let panel = Color(red: 0.12, green: 0.14, blue: 0.16)
    static let border = Color(red: 0.39, green: 0.36, blue: 0.31)
    static let ink = Color(red: 0.98, green: 0.91, blue: 0.79)
    static let secondary = Color(red: 0.71, green: 0.69, blue: 0.65)
    static let amber = Color(red: 1.0, green: 0.66, blue: 0.23)
    static let buttonInk = Color(red: 0.10, green: 0.085, blue: 0.07)
}

struct FocusApartmentButtonStyle: ButtonStyle {
    var primary = false
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(primary ? FocusApartmentStyle.buttonInk : FocusApartmentStyle.ink)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(primary ? FocusApartmentStyle.amber : FocusApartmentStyle.panel.opacity(0.96), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(primary ? FocusApartmentStyle.amber : FocusApartmentStyle.border))
            .contentShape(RoundedRectangle(cornerRadius: 13))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
    }
}
