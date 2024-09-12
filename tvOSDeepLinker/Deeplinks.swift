//
//  Deeplinks.swift
//  tvOSDeepLinker
//
//  Created by Vlad Stanescu on 12.09.2024.
//

import Foundation

enum DeeplinkType: String, CaseIterable {
    static var allCases: [DeeplinkType] {
        [.play, .navigate]
    }
    case play = "Play"
    case navigate = "Navigate"
    case noType
}

struct Deeplink: Identifiable, Hashable {
    
    
    var id = UUID()
    var urlString: String
    var type: DeeplinkType
}

extension Deeplink {
    static var mocked: [Deeplink] = [
        .init(urlString:  "mgmplus://play/series/war-of-the-worlds/season/1/episode/1/war-of-the-worlds-s1-e1", type: .play),
        .init(urlString: "mgmplus://navigate/series/from/season/1/episode/1/from-s1-e1", type: .navigate)
        
    ]
}
