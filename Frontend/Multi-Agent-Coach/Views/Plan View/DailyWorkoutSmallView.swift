//
//  DailyWorkoutSmallView.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-10-09.
//

import SwiftUI

struct DailyWorkoutSmallView: View {
    var workouts: [WorkoutSession]
    var date: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(date)
                    .font(.zenTitle3)
                    .foregroundStyle(raspberry)
                Spacer()
//                ForEach(workouts) { workout in
//                    workoutTag(workout: workout)
//                }
            }
            ForEach(workouts, id: \.id) { workout in
                let image = "\(workout.activity.displayName)Tag"
                Text("\(getCustomImage(image: image))  \(workout.sessionDescription)")
                    .font(.zenBody)
            }

            
        }
        .padding(6)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)  
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.50)
                    .shadow(.drop(color: .black.opacity(0.55), radius: 4, x:0, y: 0))
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(vermillion, lineWidth: 2)
                
        )
    }
    
    private func getCustomImage(image: String, color: Color = .gray, newSize: CGSize = CGSize(width: 62, height: 21)) -> Text {
        if let image = UIImage(named: image),
           let newImage = convertImageToNewFrame(image: image, newFrameSize: newSize) {
            return Text(
                Image(uiImage: newImage)
                    //.renderingMode(.template)
            )
            .baselineOffset(-4.0)
            .foregroundStyle(color)
            
        }
        return Text(Image(systemName: "heart.fill"))
    }
    
    func convertImageToNewFrame(image: UIImage, newFrameSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newFrameSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newFrameSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
   
}

/// Example code for how to put images inline with text
struct InlineView: View {
    private var text = "This is a multi-line text. It has multiple lines. It has multiple lines. It has multiple lines. It has multiple lines. "
    private var image = "runningTag" // Replace with your image name
    private let font: Font = .system(size: 17)
    
    var body: some View {
        Text("\(text) \(getCustomImage(image: image))")
            .font(font)
    
    }
    
    private func getCustomImage(image: String, color: Color = .gray, newSize: CGSize = CGSize(width: 62, height: 21)) -> Text {
        if let image = UIImage(named: image),
           let newImage = convertImageToNewFrame(image: image, newFrameSize: newSize) {
            return Text(
                Image(uiImage: newImage)
                    //.renderingMode(.template)
            )
            .baselineOffset(-1.5)
            .foregroundStyle(color)
            
        }
        return Text(Image(systemName: "heart.fill"))
    }
    
    func convertImageToNewFrame(image: UIImage, newFrameSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newFrameSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newFrameSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

//#Preview {
//    InlineView()
//}


#Preview {
    DailyWorkoutSmallView(workouts: [dummyClimbingSession1, dummyClimbingSession2], date: "Monday - Oct 6th")
    //InlineView()
}
