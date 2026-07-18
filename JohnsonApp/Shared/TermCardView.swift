//
//  TermCardView.swift
//  JohnsonApp
//

import SwiftUI

struct TermCardView<Accessory: View>: View {
    let termText: String
    let translation: String
    let hint: String?
    let onDelete: (() -> Void)?
    let accessory: Accessory
    
    init(
        termText: String,
        translation: String,
        hint: String?,
        onDelete: (() -> Void)? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.termText = termText
        self.translation = translation
        self.hint = hint
        self.onDelete = onDelete
        self.accessory = accessory()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(termText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(translation)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    accessory
                    
                    if let onDelete = onDelete {
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .imageScale(.medium)
                        }
                    }
                }
            }
            
            if let hint = hint, !hint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Divider()
                    .padding(.top, 4)
                
                HStack(spacing: 4) {
                    Image(systemName: "pencil.line")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(hint)
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        TermCardView(
            termText: "apple",
            translation: "яблуко",
            hint: "не бренд", accessory:  {
                Text("NEW")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .foregroundStyle(.blue)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            })
        
        TermCardView(
            termText: "banana",
            translation: "банан",
            hint: nil
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
