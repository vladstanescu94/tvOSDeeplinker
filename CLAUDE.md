# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a tvOS SwiftUI application called tvOSDeepLinker that provides a testing tool for deeplinks. The app currently handles deeplinks for the MGM+ app, but is designed to be extensible to handle deeplinks for multiple apps in the future. Users can either select predefined deeplinks from a list or manually input deeplinks to test various app URL schemes.

## Build Commands

This is an Xcode project that builds using standard Xcode build commands:

```bash
# Build the project
xcodebuild -project tvOSDeepLinker.xcodeproj -scheme tvOSDeepLinker build

# Build for tvOS device
xcodebuild -project tvOSDeepLinker.xcodeproj -scheme tvOSDeepLinker -destination 'platform=tvOS,name=Apple TV' build

# Build for tvOS Simulator
xcodebuild -project tvOSDeepLinker.xcodeproj -scheme tvOSDeepLinker -destination 'platform=tvOS Simulator,name=Apple TV' build
```

## Architecture

### Main Application Structure

- **App Entry Point**: `tvOSDeepLinkerApp.swift` - Main SwiftUI App with NavigationStack containing HomeView
- **Feature-Based Architecture**: Organized under `Features/` directory with MVVM pattern
- **Target Platform**: tvOS 17.6+ with Swift 5.0

### Core Features

1. **Home Feature** (`Features/Home/`)
   - `HomeView.swift` - Main UI with toggle for manual/list selection
   - `LinkerViewModel.swift` - Handles deeplink opening logic via UIApplication.shared.open()
   - `Deeplink.swift` - Model with predefined MGM+ deeplinks

2. **Deeplink Picker Feature** (`Features/DeeplinkPicker/`)
   - `DeeplinkList.swift` - List view for selecting predefined deeplinks organized by type

### URL Scheme

The app currently tests deeplinks with the `mgmplus://` URL scheme, but is designed to support multiple app schemes:
- Play actions: `mgmplus://play/series/[series-name]/season/[season]/episode/[episode]/[episode-identifier]`
- Navigate actions: `mgmplus://navigate/series/[series-name]/season/[season]/episode/[episode]/[episode-identifier]`
- Future extensibility planned for additional app URL schemes

### Reference Implementation Files

The `OtherResources/` directory contains reference implementation files from the main MGM+ app:

- **ApplicationTVCoordinator.swift** - Main coordinator handling app flow, authentication, and deeplink routing
- **DeepLinkRouter.swift** - Comprehensive deeplink routing system using DPLDeepLinkRouter
- **DeepLinkingRoute.swift** - Route definitions for all supported deeplink patterns
- **MGM+ Icon/** - App icon assets for the target application

### Key Implementation Details

- Uses ObservableObject/StateObject pattern for state management
- Manual deeplink input defaults to "mgmplus://" prefix
- Deeplinks are categorized by type (Play vs Navigate)
- Predefined deeplinks include War of the Worlds and From series examples
- UI uses standard SwiftUI components optimized for tvOS (NavigationStack, List, Toggle, TextField, Button)

### Development Notes

- Project uses file system synchronized groups (PBXFileSystemSynchronizedRootGroup) in Xcode
- Asset catalogs include layered icons for tvOS App Store and home screen
- Development team configured as "7A6QR7NGZZ"
- Bundle identifier: `com.vladstanescu.tvOSDeepLinker`

## AI Assistant Instructions

### Expertise and Approach

The AI assistant is configured as an expert iOS and tvOS software engineer with extensive industry experience and deep knowledge in:
- Software architectures and design patterns
- Clean code principles and SOLID principles  
- iOS/tvOS best practices and platform conventions
- SwiftUI and UIKit frameworks

### Development Philosophy

- **Clean Implementation**: Strives for clean, maintainable code implementations
- **Anti-Over-engineering**: Actively avoids unnecessary complexity and over-engineering
- **Collaborative Approach**: Always consults with the user and provides clear implementation details and reasoning
- **Proactive Agent Usage**: Leverages available sub-agents when appropriate to enhance productivity

### Agent Data Directory

The AI assistant is authorized to create and manage an "Agent Data" directory for storing important project information:
- **Purpose**: Store markdown files containing important discussions and decisions
- **Usage**: Create files when user requests to save important conversations or architectural decisions
- **Access**: Full read/write access to maintain project knowledge base
- **Context Reference**: ALWAYS reference files in the Agent Data directory for additional context when working on tasks or answering questions about the project. This directory contains comprehensive analyses, architectural decisions, and workflow documentation that provide essential context for understanding the project structure and requirements.