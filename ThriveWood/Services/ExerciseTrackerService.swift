//
//  ExerciseTrackerService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.06.26.
//

import Foundation
import CoreLocation
import SwiftUI

@MainActor
@Observable
final class ExerciseTrackerService: NSObject, CLLocationManagerDelegate {
    private(set) var isTracking = false
    private(set) var isPaused = false
    private(set) var elapsedSeconds: Int = 0
    private(set) var distanceMeters: Double = 0
    private(set) var trackingType: ExerciseTrackingType = .duration

    private var timer: Timer?
    private var startDate: Date?
    private var pausedElapsed: Int = 0

    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var locations: [CLLocation] = []

    // MARK: - Persistence Keys
    private static let kTrackerActive = "exerciseTrackerActive"
    private static let kTrackerStartDate = "exerciseTrackerStartDate"
    private static let kTrackerPausedElapsed = "exerciseTrackerPausedElapsed"
    private static let kTrackerIsPaused = "exerciseTrackerIsPaused"
    private static let kTrackerDistance = "exerciseTrackerDistance"
    private static let kTrackerType = "exerciseTrackerType"
    private static let kTrackerSetEntryId = "exerciseTrackerSetEntryId"
    private static let kTrackerSessionId = "exerciseTrackerSessionId"

    var formattedElapsed: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    var formattedDistance: String {
        let km = distanceMeters / 1000
        return String(format: "%.2f", km)
    }

    var formattedPace: String {
        guard distanceMeters > 0, elapsedSeconds > 0 else { return "--:--" }
        let secondsPerKm = Double(elapsedSeconds) / (distanceMeters / 1000)
        let paceMin = Int(secondsPerKm) / 60
        let paceSec = Int(secondsPerKm) % 60
        return String(format: "%d:%02d", paceMin, paceSec)
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5
        locationManager.activityType = .fitness
    }

    // MARK: - Persisted State

    struct PersistedState {
        let setEntryId: UUID
        let sessionId: UUID
        let trackingType: ExerciseTrackingType
        let startDate: Date
        let pausedElapsed: Int
        let isPaused: Bool
        let distanceMeters: Double
    }

    var savedState: PersistedState? {
        guard UserDefaults.standard.bool(forKey: Self.kTrackerActive),
              let startDate = UserDefaults.standard.object(forKey: Self.kTrackerStartDate) as? Date,
              let typeRaw = UserDefaults.standard.string(forKey: Self.kTrackerType),
              let type = ExerciseTrackingType(rawValue: typeRaw),
              let setIdStr = UserDefaults.standard.string(forKey: Self.kTrackerSetEntryId),
              let setId = UUID(uuidString: setIdStr),
              let sessionIdStr = UserDefaults.standard.string(forKey: Self.kTrackerSessionId),
              let sessionId = UUID(uuidString: sessionIdStr)
        else { return nil }

        return PersistedState(
            setEntryId: setId,
            sessionId: sessionId,
            trackingType: type,
            startDate: startDate,
            pausedElapsed: UserDefaults.standard.integer(forKey: Self.kTrackerPausedElapsed),
            isPaused: UserDefaults.standard.bool(forKey: Self.kTrackerIsPaused),
            distanceMeters: UserDefaults.standard.double(forKey: Self.kTrackerDistance)
        )
    }

    func restore(from state: PersistedState) {
        trackingType = state.trackingType
        isTracking = true
        isPaused = state.isPaused
        pausedElapsed = state.pausedElapsed
        distanceMeters = state.distanceMeters
        startDate = state.startDate

        if state.isPaused {
            elapsedSeconds = state.pausedElapsed
        } else {
            elapsedSeconds = state.pausedElapsed + Int(Date.now.timeIntervalSince(state.startDate))
        }

        if trackingType == .distanceDuration {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }

        if !state.isPaused {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.tick() }
            }
        }
    }

    // MARK: - Lifecycle

    func start(trackingType: ExerciseTrackingType) {
        stop()
        self.trackingType = trackingType
        isTracking = true
        isPaused = false
        elapsedSeconds = 0
        distanceMeters = 0
        pausedElapsed = 0
        startDate = .now
        lastLocation = nil
        locations = []

        if trackingType == .distanceDuration {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        Haptics.impact(.medium)
    }

    func start(trackingType: ExerciseTrackingType, setEntryId: UUID, sessionId: UUID) {
        start(trackingType: trackingType)
        saveState(setEntryId: setEntryId, sessionId: sessionId)
    }

    func pause() {
        guard isTracking, !isPaused else { return }
        isPaused = true
        pausedElapsed = elapsedSeconds
        timer?.invalidate()
        timer = nil
        if trackingType == .distanceDuration {
            locationManager.stopUpdatingLocation()
        }
        savePausedState()
        Haptics.selection()
    }

    func resume() {
        guard isTracking, isPaused else { return }
        isPaused = false
        startDate = .now
        if trackingType == .distanceDuration {
            locationManager.startUpdatingLocation()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        savePausedState()
        Haptics.selection()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        locationManager.stopUpdatingLocation()
        isTracking = false
        isPaused = false
        clearState()
    }

    private func tick() {
        guard let startDate, !isPaused else { return }
        elapsedSeconds = pausedElapsed + Int(Date.now.timeIntervalSince(startDate))
        saveDistanceState()
    }

    // MARK: - Persistence

    private func saveState(setEntryId: UUID, sessionId: UUID) {
        UserDefaults.standard.set(true, forKey: Self.kTrackerActive)
        UserDefaults.standard.set(startDate, forKey: Self.kTrackerStartDate)
        UserDefaults.standard.set(pausedElapsed, forKey: Self.kTrackerPausedElapsed)
        UserDefaults.standard.set(isPaused, forKey: Self.kTrackerIsPaused)
        UserDefaults.standard.set(distanceMeters, forKey: Self.kTrackerDistance)
        UserDefaults.standard.set(trackingType.rawValue, forKey: Self.kTrackerType)
        UserDefaults.standard.set(setEntryId.uuidString, forKey: Self.kTrackerSetEntryId)
        UserDefaults.standard.set(sessionId.uuidString, forKey: Self.kTrackerSessionId)
    }

    private func savePausedState() {
        UserDefaults.standard.set(pausedElapsed, forKey: Self.kTrackerPausedElapsed)
        UserDefaults.standard.set(isPaused, forKey: Self.kTrackerIsPaused)
        UserDefaults.standard.set(distanceMeters, forKey: Self.kTrackerDistance)
    }

    private func saveDistanceState() {
        UserDefaults.standard.set(distanceMeters, forKey: Self.kTrackerDistance)
        UserDefaults.standard.set(elapsedSeconds, forKey: Self.kTrackerPausedElapsed)
        if isPaused {
            UserDefaults.standard.set(startDate, forKey: Self.kTrackerStartDate)
        }
    }

    private func clearState() {
        UserDefaults.standard.removeObject(forKey: Self.kTrackerActive)
        UserDefaults.standard.removeObject(forKey: Self.kTrackerStartDate)
        UserDefaults.standard.removeObject(forKey: Self.kTrackerPausedElapsed)
        UserDefaults.standard.removeObject(forKey: Self.kTrackerIsPaused)
        UserDefaults.standard.removeObject(forKey: Self.kTrackerDistance)
        UserDefaults.standard.removeObject(forKey: Self.kTrackerType)
        UserDefaults.standard.removeObject(forKey: Self.kTrackerSetEntryId)
        UserDefaults.standard.removeObject(forKey: Self.kTrackerSessionId)
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let newLocation = locations.last else { return }
            guard newLocation.horizontalAccuracy > 0 && newLocation.horizontalAccuracy < 20 else { return }

            if let last = lastLocation {
                let delta = newLocation.distance(from: last)
                if delta > 2 {
                    self.distanceMeters += delta
                    self.lastLocation = newLocation
                }
            } else {
                self.lastLocation = newLocation
            }
            self.locations.append(newLocation)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}