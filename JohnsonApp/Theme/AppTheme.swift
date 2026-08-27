//
//  AppTheme.swift
//  JohnsonApp
//

import SwiftUI

public enum AppTheme {
    public static let sageGreen = Color(red: 0.4, green: 0.57, blue: 0.34) // #669157
    public static let accentBlue = Color(red: 0.2, green: 0.38, blue: 0.77) // #3361C4
    
    public static let backgroundColor = Color(.systemGroupedBackground)
    public static let cardBackgroundColor = Color(.secondarySystemGroupedBackground)
}

struct HeaderBannerView<TrailingContent: View>: View {
    let title: String
    let imageName: String
    let trailingContent: TrailingContent
    
    init(
        title: String,
        imageName: String = "cat",
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() }
    ) {
        self.title = title
        self.imageName = imageName
        self.trailingContent = trailingContent()
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
            }
            
            Spacer()
            
            trailingContent
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
        }
        .padding(.horizontal, 20)
        .background(
            AppTheme.sageGreen
                .ignoresSafeArea(edges: .top)
        )
    }
}

extension View {
    func appCardStyle(
        cornerRadius: CGFloat = 16,
        borderColor: Color = AppTheme.sageGreen.opacity(0.3),
        borderWidth: CGFloat = 1.5
    ) -> some View {
        self
            .background(AppTheme.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
    }
}
