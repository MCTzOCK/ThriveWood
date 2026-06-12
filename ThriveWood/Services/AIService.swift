//
//  AIService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.05.26.
//


import Foundation
import Combine
import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
@Observable
final class AIService {
    
    #if os(iOS)
    private final let model = SystemLanguageModel.default
    
    public func isAvailable() -> Bool {
        return model.availability == .available
    }
    
    public func stream(for prompt: String) -> LanguageModelSession.ResponseStream<String> {
        let session = LanguageModelSession(model: model)
        return session.streamResponse(to: prompt)
    }
    #else
    public func isAvailable() -> Bool {
        if #available(macOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        return false
    }
    
    @available(macOS 26.0, *)
    public func stream(for prompt: String) -> LanguageModelSession.ResponseStream<String> {
        let session = LanguageModelSession(model: SystemLanguageModel.default)
        return session.streamResponse(to: prompt)
    }
    #endif
}
