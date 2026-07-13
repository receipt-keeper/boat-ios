//
//  UIApplication+RootViewController.swift
//  BOAT
//
//  UMP 동의 폼, 네이티브 광고 클릭 액션 등 UIKit 프레젠테이션이 필요한 지점에서 공용으로 쓴다.
//

import UIKit

extension UIApplication {
    static var boatRootViewController: UIViewController? {
        shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
    }
}
