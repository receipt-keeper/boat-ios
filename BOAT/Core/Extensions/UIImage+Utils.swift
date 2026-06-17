//
//  UIImage+Utils.swift
//  BOAT
//

import UIKit

extension UIImage {

    private static let sizeLimitMB: Double = 10.0

    var fileSizeInBytes: Int {
        jpegData(compressionQuality: 1.0)?.count ?? 0
    }

    var fileSizeInMB: Double {
        Double(fileSizeInBytes) / (1024 * 1024)
    }

    var isUnderSizeLimit: Bool {
        fileSizeInMB <= UIImage.sizeLimitMB
    }
}
