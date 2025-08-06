//
//  ContentView.swift
//  tvOSDeepLinker
//
//  Created by Vlad Stanescu on 12.09.2024.
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = LinkerViewModel()
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Deeplinker")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                // List Selection Section
                VStack(spacing: 8) {
                    NavigationLink("Select from list", value: "list")
                        .disabled(self.viewModel.showManual)
                    
                    // Show currently selected deeplink when in list mode
                    if !self.viewModel.showManual && !self.viewModel.selectedDeeplink.urlString.isEmpty {
                        VStack(spacing: 8) {
                            Text("Selected:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(self.viewModel.selectedDeeplink.urlString)
                                .font(.footnote)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                        }
                    }
                }
                
                // Manual Input Section
                VStack(spacing: 12) {
                    Toggle("Manual input mode", isOn: self.$viewModel.showManual)
                    
                    if self.viewModel.showManual {
                        TextField("Insert deeplink", text: $viewModel.manualLinkFieldValue)
                    }
                }
            }
            
            // Trigger Button
            Button("Trigger Deeplink") {
                self.viewModel.openDeeplink()
            }
            .font(.title3)
            .fontWeight(.semibold)
            
            Spacer()
        }
        .padding(40)
        .navigationDestination(for: String.self) { _ in
            DeeplinkList(viewModel: self.viewModel)
        }
    }
}


#Preview {
    HomeView()
}
