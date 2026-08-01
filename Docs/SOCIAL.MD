# SOCIAL.MD — Technische Ansätze für soziale Features ohne Backend

## Ausgangslage

ThriveWood nutzt SwiftData für lokale Speicherung. Aus Datenschutzgründen soll kein klassisches Backend (Server, Datenbank) eingesetzt werden. Diese Dokumentation beschreibt rein technische Möglichkeiten, wie soziale Features dennoch umgesetzt werden könnten — ohne zentrale Infrastruktur.

---

## 1. Multipeer Connectivity (Apple P2P Framework)

**Funktionsweise:** Geräte im selben WLAN oder via Bluetooth verbinden sich direkt (Peer-to-Peer). Apple's `MultipeerConnectivity` Framework übernimmt Discovery, Authentifizierung und sicheren Datenaustausch.

### Technische Details

```swift
import MultipeerConnectivity

// Service Setup
let peerID = MCPeerID(displayName: UIDevice.current.name)
let session = MCSession(peer: peerID)
let advertiser = MCAdvertiserAssistant(serviceType: "thrivewood-social", discoveryInfo: nil, session: session)
let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "thrivewood-social")

// Daten senden (z.B. Punkte, Forest-Screenshot)
let data = try JSONEncoder().encode(payload)
try session.send(data, toPeers: session.connectedPeers, with: .reliable)

// Daten empfangen
func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    let payload = try JSONDecoder().decode(SocialPayload.self, from: data)
}
```

### Anwendungsbeispiele

- **Nutzer in Nähe finden:** "ThriveWood-Nutzer:innen in deiner Umgebung" — Anzeige von Display Names in Reichweite
- **Live-Challenges:** "Wer sammelt die meisten Punkte in den nächsten 10 Minuten?" — Direkte Synchronisation der Punktestände
- **Forest-Vergleich:** Side-by-Side Anzeige der Wälder beider Nutzer auf einem Screen

### Vorteile

- ✅ Kein Server, keine Cloud
- ✅ Apple-Standard, hohe Sicherheit (verschlüsselt)
- ✅ Funktioniert offline (lokales Netzwerk/Bluetooth)
- ✅ Datenschutzfreundlich — Nutzer müssen explizit verbinden

### Nachteile

- ❌ Nur in physischer Nähe (Bluetooth ~10m, WLAN im selben Netz)
- ❌ Kein persistentes soziales Netzwerk (keine "Freundesliste")
- ❌ iOS-only (keine Android-Unterstützung)

---

## 2. QR-Code basierte Verbindung

**Funktionsweise:** Ein Nutzer generiert einen QR-Code mit seiner öffentlichen ID (UUID). Der andere scannt diesen und speichert die Verbindung lokal.

### Technische Details

```swift
// Public User ID generieren (einmalig bei App-Install)
let publicUserID = UUID().uuidString

// QR-Code generieren
let payload = SocialProfile(userID: publicUserID, name: "Ben", level: 12)
let qrData = try JSONEncoder().encode(payload)
let qrCode = QRCodeGenerator.generate(from: qrData)

// QR-Code scannen
let scannedData = QRCodeScanner.scan()
let profile = try JSONDecoder().decode(SocialProfile.self, from: scannedData)

// Lokal speichern
savedFriends.append(profile)
```

### Anwendungsbeispiele

- **Freundesliste:** Lokale Liste von `Friend`-Objekten in SwiftData
- **Manueller Austausch:** Treffen mit Freunden, QR-Code scannen, verbinden
- **Profile teilen:** "Mein Profil"-QR auf Social Media posten

### Vorteile

- ✅ Kein Server, voll lokal
- ✅ Funktioniert vollständig offline
- ✅ Nutzer hat volle Kontrolle über Verbindungen
- ✅ Einfach implementierbar

### Nachteile

- ❌ Kein automatischer Sync (manueller Austausch nötig)
- ❌ Keine Online-Präsenz (wer ist gerade aktiv?)
- ❌ Kein "Freund hinzufügen" per Suche/Username

---

## 3. Game Center Integration

**Funktionsweise:** Apple's `GameKit` bietet soziale Features (Freundeslisten, Leaderboards, Achievements) ohne eigene Backend-Infrastruktur.

### Technische Details

```swift
import GameKit

// Authentifizierung
GKLocalPlayer.local.authenticateHandler = { viewController, error in
    if let vc = viewController {
        // Game Center Login präsentieren
    }
}

// Leaderboard Score senden
let score = GKScore(leaderboardIdentifier: "thrivewood_weekly_points")
score.value = Int64(totalPoints)
GKScore.report([score]) { error in }

// Achievements freischalten
let achievement = GKAchievement(identifier: "first_100_points")
achievement.percentComplete = 100.0
achievement.showsCompletionBanner = true
GKAchievement.report([achievement]) { error in }

// Freundesliste abrufen
GKLocalPlayer.local.loadFriends { friends, error in
    for friend in friends ?? [] {
        print(friend.displayName)
    }
}
```

### Anwendungsbeispiele

- **Wöchentliche Rangliste:** "Punkte dieser Woche" — Globaler Leaderboard
- **Achievements:** Badges in Game Center sichtbar
- **Freundes-Comparison:** Punktevergleich mit Game Center Freunden

### Vorteile

- ✅ Apple-verwaltet (kein eigener Server)
- ✅ Globale Ranglisten möglich
- ✅ Integrierte Freundesliste
- ✅ Cross-Platform (iOS, iPadOS, macOS)

### Nachteile

- ❌ Nutzer benötigen Game Center Account
- ❌ Weniger Kontrolle über UX (Game Center UI)
- ❌ Begrenzte Daten — nur Scores, kein komplexer Datenaustausch

---

## 4. iCloud Public Database (CloudKit)

**Funktionsweise:** `CloudKit` bietet öffentliche Datenbanken, die von allen Nutzern gelesen werden können — ohne eigenen Server.

### Technische Details

```swift
import CloudKit

let container = CKContainer(identifier: "iCloud.com.yourapp.thrivewood")
let publicDB = container.publicCloudDatabase

// Nutzer-Profil speichern (Public Record)
let record = CKRecord(recordType: "UserProfile")
record["userID"] = publicUserID
record["displayName"] = "Ben"
record["weeklyPoints"] = 1250

publicDB.save(record) { savedRecord, error in }

// Leaderboard abrufen
let query = CKQuery(recordType: "UserProfile", predicate: NSPredicate(value: true))
query.sortDescriptors = [NSSortDescriptor(key: "weeklyPoints", ascending: false)]

publicDB.perform(query, inZoneWith: nil) { records, error in
    let leaderboard = records?.map { $0["weeklyPoints"] as? Int ?? 0 }
}
```

### Anwendungsbeispiele

- **Globaler Leaderboard:** Top 100 Nutzer dieser Woche
- **Challenge-Teilnahme:** Public Record pro Challenge mit Punktestand
- **Anonymes Social:** Keine direkte Kommunikation, nur Ranglisten

### Vorteile

- ✅ Apple verwaltet Infrastruktur
- ✅ Globale Daten ohne eigenen Server
- ✅ Nutzer müssen sich nicht registrieren (iCloud-Account reicht)
- ✅ Sync funktioniert automatisch

### Nachteile

- ⚠️ Technisch gesehen ein Backend (Apple's CloudKit Server)
- ❌ Öffentliche Daten — jeder kann alles lesen (nur eigene Records schreibbar)
- ❌ DSGVO/Privacy-Aspekte prüfen (Daten auf Apple-Servern)
- ❌ Keine Echtzeit-Kommunikation

---

## 5. Nearby Interaction (UWB - Ultra Wideband)

**Funktionsweise:** iPhone 11+ hat U1 Chip für präzise Entfernungsmessung. `NearbyInteraction` ermöglicht Peer-Discovery mit cm-Genauigkeit.

### Technische Details

```swift
import NearbyInteraction

let token = try await NISession().discoverPeers()
// Token austauschen (via MultipeerConnectivity oder Server)
let peerToken = ...

let session = NISession()
let config = NINearbyPeerConfiguration(peerToken: peerToken)
session?.run(config)

func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
    let distance = nearbyObjects.first?.distance // in Metern
    let direction = nearbyObjects.first?.direction // AR-Einblendung möglich
}
```

### Anwendungsbeispiele

- **"In deiner Nähe"-Features:** Nur Nutzer <2m Entfernung werden angezeigt
- **AR-Social:** Forest in AR über Freundes-Handy projizieren
- **Gym-Challenges:** Wer im Gym ist, sieht andere ThriveWood-Nutzer dort

### Vorteile

- ✅ Sehr präzise Entfernungsmessung
- ✅ Kombinierbar mit Multipeer Connectivity

### Nachteile

- ❌ Nur iPhone 11+ (U1 Chip nötig)
- ❌ Nur für "in der Nähe"-Szenarien
- ❌ Komplexe Implementierung

---

## 6. Export/Import basiertes Teilen

**Funktionsweise:** Nutzer exportiert Daten (JSON/Bild), teilt via AirDrop/Mail/Messaging-Apps.

### Technische Details

```swift
// Export Forest als JSON
let forestData = try JSONEncoder().encode(forestService.currentForest)
let url = FileManager.default.temporaryDirectory.appendingPathComponent("forest.json")
try forestData.write(to: url)

let shareSheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
present(shareSheet, animated: true)

// Import
let importedData = try Data(contentsOf: importedURL)
let forest = try JSONDecoder().decode(Forest.self, from: importedData)
```

### Anwendungsbeispiele

- **Forest teilen:** Screenshot oder JSON-Export an Freund senden
- **Challenge-Einladung:** Vordefinierte 30-Tage-Challenge als JSON teilen
- **Backup teilen:** Eltern können Daten an Kinder weitergeben

### Vorteile

- ✅ Voll lokal, kein Netzwerk nötig
- ✅ Volle Kontrolle über Datenfluss
- ✅ Funktioniert mit allen Apps (WhatsApp, Mail, etc.)

### Nachteile

- ❌ Kein Echtzeit-Sync
- ❌ Manueller Prozess
- ❌ Keine automatische Aktualisierung

---

## 7. Widget-Integration für sozialen Druck

**Funktionsweise:** Widgets auf dem Homescreen zeigen Freunden/dritten den Punktestand — indirektes soziales Feature.

### Technische Details

```swift
// Widget zeigt Punkte-Widget auf Homescreen
// Freunde sehen bei Besuch: "Ben hat heute 450 Punkte"

// Live Activity während Workout zeigt:
// "Ben trainiert gerade — Satz 3/4"
```

### Anwendungsbeispiele

- **Öffentliche Anzeige:** Homescreen-Widget für Freunde sichtbar
- **Live Activity:** Andere sehen, dass du trainierst

### Vorteile

- ✅ Kein Netzwerk, rein lokal
- ✅ Motiviert durch Sichtbarkeit

### Nachteile

- ❌ Nur indirekt "sozial"
- ❌ Keine Interaktion

---

## Empfehlung für ThriveWood

Angesichts der Datenschutz-Anforderungen und lokalen Architektur:

### Kurzfristig (ohne Server)

1. **Game Center Integration** — Für globale Leaderboards ohne Backend
2. **Export/Share-Modul** — Forest-Screenshots, PR-Karten teilen
3. **QR-Code Freundesliste** — Lokale Freundesverwaltung

### Mittelfristig (P2P)

4. **Multipeer Connectivity** — Für Live-Challenges im Gym/Freundeskreis
5. **Nearby Interaction** — Für "Nutzer in deiner Nähe"-Features (iPhone 11+)

### Langfristig (Privacy-first Backend Alternative)

6. **CloudKit Public Database** — Wenn globale Ranglisten ohne eigener Server gewünscht

---

## Datenschutz-Checkliste

Bei allen Ansätzen gilt:

- [ ] Nutzer muss explizit einwilligen ("Social Features aktivieren")
- [ ] Keine Daten ohne Einwilligung teilen
- [ ] Exporte enthalten nur aggregierte Daten (keine Roh-Habits)
- [ ] Freundeslisten lokal speichern, niemals auf Server hochladen
- [ ] Opt-out jederzeit möglich
- [ ] DSGVO-konforme Datenschutzerklärung erweitern

---

## Fazit

**Rein lokal ohne jedes Backend:**
- QR-Code Freundesliste + Export/Share
- Multipeer Connectivity für direkte P2P-Verbindungen
- Game Center für Apple-verwaltete Leaderboards

**Mit Apple-verwalteter Infrastruktur (kein eigener Server):**
- CloudKit Public Database für globale Ranglisten
- Game Center für Achievements + Freundesvergleich

**Nicht empfohlen:**
- Eigenes Backend (verstößt gegen Privacy-Prinzip)
- Third-Party Auth (Firebase, Supabase) — Datenschutzrisiko

---

> **Letzte Aktualisierung:** 2026-06-05
