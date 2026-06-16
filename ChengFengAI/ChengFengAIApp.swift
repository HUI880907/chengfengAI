import SwiftUI

@main
struct ChengFengAIApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 20) {
                Image(systemName: "brain")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("乘风AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("智能助手")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "message.circle")
                        Text("开始对话")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}
