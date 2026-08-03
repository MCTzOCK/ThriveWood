//
//  StatusBarController.swift
//  ThriveWood
//
//  App-weit weiße Statusleiste.
//
//  Die eigentliche Steuerung erfolgt über die Info.plist-Schlüssel
//  (UIViewControllerBasedStatusBarAppearance = NO,
//   UIStatusBarStyle = UIStatusBarStyleLightContent). Dieses File hält
//  einen optionalen SwiftUI-Hook bereit, falls View-lokal der Style
//  zurückgesetzt werden muss (z. B. in hellen Vollbild-Sheets).
//

import SwiftUI

extension View {
    /// Marker-Methode — App-weit ist weiße Statusleiste via Info.plist
    /// aktiviert. Dieser Modifier ist ein No-Op und dient nur der
    /// Lesbarkeit an Aufrufstellen.
    func lightStatusBar() -> some View { self }
}
