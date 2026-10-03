import SwiftUI

struct SoloRoomView: View {
    var body: some View { StudySessionFlowView(group: false) }
}

#Preview { SoloRoomView().environment(AppStore()) }
