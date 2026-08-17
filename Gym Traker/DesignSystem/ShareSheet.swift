//
//  ShareSheet.swift
//  Gym Traker
//
//  The system share sheet, for the case `ShareLink` cannot cover: something
//  that does not exist until the button is pressed.
//
//  `ShareLink` needs its item up front, so the plan's PDF button had to be a
//  different button — with a different icon — until a PDF had been made, and
//  then turn into a share button. Two icons in one place, and the first one
//  gave no clue that pressing it led to sharing. The file is made on the way
//  to the sheet instead.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
