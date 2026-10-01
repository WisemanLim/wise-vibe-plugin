import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, {{PROJECT_NAME}} (\(Env.flavor))")
                .font(.largeTitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
