//
//  ContentView.swift
//  tvOSDeepLinker
//
//  Created by Vlad Stanescu on 12.09.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = LinkerViewModel()
    var body: some View {
        VStack {
            Text("Deeplinker")
                .font(.largeTitle)
            
            NavigationLink("Select from list", value: "list")
                .disabled(self.viewModel.showManual)
            
            VStack {
                Toggle("Toggle manual", isOn: self.$viewModel.showManual)
                
                if self.viewModel.showManual {
                    TextField("Insert deeplink", text: $viewModel.manualLinkFieldValue)
                }
            }
            
            Button(action: {
                self.viewModel.openDeeplink()
            }, label: {
                Text("Trigger Deeplink")
            })
            
            Spacer()
        }
        .padding()
        .navigationDestination(for: String.self) { _ in
            DeeplinkList(viewModel: self.viewModel)
        }
    }
}

#Preview {
    ContentView()
}
