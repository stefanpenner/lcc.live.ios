import Foundation
import SwiftUI

func calculateGridLayout(
    availableWidth: CGFloat,
    availableHeight: CGFloat,
    gridMode: PhotoTabView.GridMode,
    spacing: CGFloat
) -> (columns: Int, imageWidth: CGFloat, imageHeight: CGFloat) {
    let isLandscape = availableWidth > availableHeight
    switch gridMode {
    case .compact:
        let compactColumns = max(2, min(4, Int(availableWidth / 220)))
        let imageWidth = (availableWidth - (CGFloat(compactColumns - 1) * spacing)) / CGFloat(compactColumns)
        let imageHeight = imageWidth * 0.7
        return (compactColumns, imageWidth, imageHeight)
    case .single:
        let maxSingleWidth: CGFloat = 430
        if isLandscape {
            let columns = 2
            let totalSpacing = spacing
            let imageWidth = min((availableWidth - totalSpacing) / 2, maxSingleWidth)
            let imageHeight = imageWidth * 0.7
            return (columns, imageWidth, imageHeight)
        } else {
            let columns = 1
            let imageWidth = min(availableWidth, maxSingleWidth)
            let imageHeight = imageWidth * 0.7
            return (columns, imageWidth, imageHeight)
        }
    }
} 