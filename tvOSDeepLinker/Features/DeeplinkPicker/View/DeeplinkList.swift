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
        VStack(spacing: 20) {
            // Header Section
            VStack(spacing: 12) {
                Text("Select Deeplink")
                    .font(.title)
                    .fontWeight(.bold)
                
                if !viewModel.selectedDeeplink.urlString.isEmpty {
                    VStack(spacing: 8) {
                        Text("Currently selected:")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.selectedDeeplink.urlString)
                            .font(.callout)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
            }
            
            // Deeplink List
            ScrollView {
                ForEach(DeeplinkType.allCases, id: \.self) { type in
                    Section {
                        ForEach(self.viewModel.deeplinks.filter { $0.type == type }) { deepLink in
                            DeeplinkRow(
                                deeplink: deepLink,
                                isSelected: deepLink.id == viewModel.selectedDeeplink.id
                            ) {
                                self.viewModel.selectedDeeplink = deepLink
                            }
                            .padding(.horizontal, 20)
                        }
                    } header: {
                        HStack {
                            Text(type.rawValue)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .listRowInsets(EdgeInsets())
                    }
                }
            }
            .padding(30)
        }
        .padding(30)
    }
}

// MARK: - DeeplinkRow Component

struct DeeplinkRow: View {
    let deeplink: Deeplink
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(extractTitle(from: deeplink.urlString))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(deeplink.urlString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
        }
    }
    
    private func extractTitle(from urlString: String) -> String {
        let components = urlString.components(separatedBy: "/")
        
        // Find series name (look for component after "series")
        var seriesName = ""
        var seasonNum = ""
        var episodeNum = ""
        
        for i in 0..<components.count {
            if components[i] == "series" && i + 1 < components.count {
                seriesName = components[i + 1].replacingOccurrences(of: "-", with: " ").capitalized
            } else if components[i] == "season" && i + 1 < components.count {
                seasonNum = components[i + 1]
            } else if components[i] == "episode" && i + 1 < components.count {
                episodeNum = components[i + 1]
            }
        }
        
        if !seriesName.isEmpty {
            if !seasonNum.isEmpty && !episodeNum.isEmpty {
                return "\(seriesName) - S\(seasonNum)E\(episodeNum)"
            }
            return seriesName
        }
        
        return urlString
    }
}

#Preview {
    DeeplinkList(viewModel: LinkerViewModel())
}
