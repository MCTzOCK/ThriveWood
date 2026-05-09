//
//  AIService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 09.05.26.
//


import Foundation
import FoundationModels
import Combine
import SwiftUI

@MainActor
@Observable
final class AIService {
    
    private final let model = SystemLanguageModel.default
    
    public func isAvailable() -> Bool {
        return model.availability == .available
    }
    
    public func stream(for prompt: String) -> LanguageModelSession.ResponseStream<String> {
        let session = LanguageModelSession(model: model)
        return session.streamResponse(to: prompt)
    }
}
