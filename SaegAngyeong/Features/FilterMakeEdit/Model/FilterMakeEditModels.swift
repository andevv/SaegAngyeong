//
//  FilterMakeEditModels.swift
//  SaegAngyeong
//
//  Created by andev on 2/6/26.
//

import UIKit

struct FilterMakeDraft {
    var title: String
    var category: FilterMakeCategory?
    var description: String
    var priceText: String
    var image: UIImage?
}

struct FilterAdjustmentValues: Equatable {
    var brightness: Double
    var exposure: Double
    var contrast: Double
    var saturation: Double
    var sharpness: Double
    var highlights: Double
    var shadows: Double
    var temperature: Double
    var vignette: Double
    var noiseReduction: Double
    var blur: Double
    var blackPoint: Double

    static let defaultValues = FilterAdjustmentValues(
        brightness: 0,
        exposure: 0,
        contrast: 1,
        saturation: 1,
        sharpness: 0,
        highlights: 0,
        shadows: 0,
        temperature: 6500,
        vignette: 0,
        noiseReduction: 0,
        blur: 0,
        blackPoint: 0
    )
}

enum FilterAdjustmentType: CaseIterable {
    case brightness
    case exposure
    case contrast
    case saturation
    case sharpness
    case highlights
    case shadows
    case temperature
    case vignette
    case noiseReduction
    case blur
    case blackPoint

    var title: String {
        switch self {
        case .brightness: return "BRIGHTNESS"
        case .exposure: return "EXPOSURE"
        case .contrast: return "CONTRAST"
        case .saturation: return "SATURATION"
        case .sharpness: return "SHARPNESS"
        case .highlights: return "HIGHLIGHTS"
        case .shadows: return "SHADOWS"
        case .temperature: return "TEMPERATURE"
        case .vignette: return "VIGNETTE"
        case .noiseReduction: return "NOISE"
        case .blur: return "BLUR"
        case .blackPoint: return "BLACK"
        }
    }

    var iconName: String {
        switch self {
        case .brightness: return "Brightness"
        case .exposure: return "Exposure"
        case .contrast: return "Contrast"
        case .saturation: return "Saturation"
        case .sharpness: return "Sharpness"
        case .highlights: return "Highlights"
        case .shadows: return "Shadows"
        case .temperature: return "Temperature"
        case .vignette: return "Vignette"
        case .noiseReduction: return "Noise"
        case .blur: return "Blur"
        case .blackPoint: return "BlackPoint"
        }
    }
}
