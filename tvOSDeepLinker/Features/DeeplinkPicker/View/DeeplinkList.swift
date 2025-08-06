//
//  DeeplinkList.swift
//  tvOSDeepLinker
//
//  Created by Vlad Stanescu on 12.09.2024.
//

import SwiftUI

struct DeeplinkList: View {
    @ObservedObject var viewModel: LinkerViewModel
    
    var body: some View {
        VStack {
            Text("Select Deeplink")
                .font(.largeTitle)
            Text("Currently selected:")
                .font(.caption)
            Text("\(viewModel.selectedDeeplink.urlString)")
            
            List {
                ForEach(DeeplinkType.allCases, id: \.self) { type in
                    Section(header: Text(type.rawValue)) {
                        ForEach(self.viewModel.deeplinks.filter { $0.type == type }) { deepLink in
                            Button(action: {
                                self.viewModel.selectedDeeplink = deepLink
                            }, label: {
                                Text(deepLink.urlString)
                            })
                        }
                    }
                }
            }
            
            
        }
    }
}

#Preview {
    DeeplinkList(viewModel: LinkerViewModel())
}
