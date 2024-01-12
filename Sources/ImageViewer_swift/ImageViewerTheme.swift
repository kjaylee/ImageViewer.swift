import UIKit

public enum ImageViewerTheme {
    case light
    case dark
    case clear
    
    var backgroundColor: UIColor {
        switch self {
        case .light:
            return .white
        case .dark:
            return .black
        case .clear:
            return .black
        }
    }
    
    var navigationColor: UIColor {
        switch self {
        case .light:
            return .black
        case .dark:
            return .white
        case .clear:
            return .clear
        }
    }
    
    var navigationItemColor: UIColor {
        switch self {
        case .light:
            return .white
        case .dark:
            return .black
        case .clear:
            return .white
        }
    }
    
    var tintColor:UIColor {
        switch self {
        case .light:
            return .black
        case .dark:
            return .white
        case .clear:
            return .black
        }
    }
}
