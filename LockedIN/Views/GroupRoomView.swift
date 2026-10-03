import SwiftUI

struct GroupRoomView: View {
    var body: some View { StudySessionFlowView(group: true) }
}

#Preview { GroupRoomView().environment(AppStore()) }
