//
//  RunningInfoCard.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-11-06.
//
import SwiftUI

struct RunningInfoCard: View {
    var runningWorkout: CompletedRunningWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                metricView(title: "Distance", value: distanceString(km: runningWorkout.distanceKm))
                Spacer(minLength: 12)
                metricView(title: "Avg Pace", value: paceString(from: runningWorkout.avgPacePerKm))
                metricView(title: "Avg HR", value: heartRateString(bpm: runningWorkout.avgHeartRate))
                Spacer(minLength: 12)
                metricView(title: "Elev Gain", value: elevationString(meters: runningWorkout.elevationGain))
            }
            
            // User Notes
            if !runningWorkout.userNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NOTES")
                        .font(.zenCaption2)
                        .foregroundStyle(jet.opacity(0.7))
                    Text(runningWorkout.userNotes)
                        .font(.zenBody)
                        .foregroundStyle(jet)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white)
                )
                .overlay(
                    // Use strokeBorder to avoid clipping artifacts
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(ash.opacity(0.5), lineWidth: 1)
                )
                // Give the stroke a tiny breathing room so it won't get visually clipped
                .padding(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Metric Pill
    
    private func metricView(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.zenCaption2)
                .foregroundStyle(jet.opacity(0.7))
            Text(value)
                .font(.zenBigHeadline)
                .foregroundStyle(jet)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 👈 Each expands equally
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white)
        )
        .overlay(
            // Use strokeBorder for cleaner edges
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(ash.opacity(0.5), lineWidth: 1)
        )
        // Tiny padding helps prevent the 1pt stroke from appearing clipped
        .padding(1)
    }

    
    // MARK: - Formatters
    
    private func distanceString(km: Float) -> String {
        let value = Double(km)
        let measurement = Measurement(value: value, unit: UnitLength.kilometers)
        let mf = MeasurementFormatter()
        mf.unitOptions = .providedUnit
        mf.numberFormatter.maximumFractionDigits = value < 10 ? 2 : 1
        return mf.string(from: measurement)
    }
    
    private func paceString(from secondsPerKm: TimeInterval) -> String {
        guard secondsPerKm > 0 else { return "—" }
        let totalSeconds = Int(secondsPerKm.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    private func heartRateString(bpm: Float) -> String {
        let value = Int(bpm.rounded())
        return value > 0 ? "\(value) bpm" : "—"
    }
    
    private func elevationString(meters: Float) -> String {
        let value = Double(meters)
        let measurement = Measurement(value: value, unit: UnitLength.meters)
        let mf = MeasurementFormatter()
        mf.unitOptions = .providedUnit
        mf.numberFormatter.maximumFractionDigits = value < 100 ? 0 : 0
        return mf.string(from: measurement)
    }
}

#Preview {
    //var running = CompletedRunningWorkout(activity: .running,userNotes: "", date: Date(), distanceKm: 0,avgHeartRate: 0,elevationGain: 0, avgPacePerKm: 0)
    AddWorkoutView(activity: .running)
    //RunningInfoCard(runningWorkout: running)
}
