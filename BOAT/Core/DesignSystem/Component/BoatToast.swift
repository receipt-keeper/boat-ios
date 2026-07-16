//
//  BoatToast.swift
//  BOAT
//
//  Android BoatToast.kt 와 동일 스펙으로 구현한 토스트.
//  - 위치: 상단 노출 / width 335(fill - 좌우 20) / height 56 / radius 8
//  - 3초 후 자동 닫힘, fade + 위에서 슬라이드 인/아웃
//  - 시스템 Toast 대신 반드시 이 컴포넌트를 사용한다.
//

import SwiftUI

// MARK: - Type

enum BoatToastType {
    case error
    case success
    case info

    /// 번짐 배경이 포함된 32×32 에셋 (icInfo/icWarning)
    var iconName: String {
        switch self {
        case .error:           return "icWarning" // 빨강 아이콘 + 10% 빨강 원
        case .success, .info:  return "icInfo"    // 파랑 아이콘 + 10% 파랑 원
        }
    }
}

// MARK: - Model

struct BoatToast: Equatable, Identifiable {
    let id = UUID()
    let message: String
    let type: BoatToastType
}

// MARK: - State

@Observable
final class BoatToastState {
    private(set) var current: BoatToast?

    func show(_ message: String, type: BoatToastType = .info) {
        current = BoatToast(message: message, type: type)
    }

    func showError(_ message: String)   { show(message, type: .error) }
    func showSuccess(_ message: String) { show(message, type: .success) }

    func dismiss() { current = nil }
}

// MARK: - Item View

struct BoatToastView: View {
    let toast: BoatToast

    var body: some View {
        HStack(spacing: .spacing12) {
            // 번짐 원 + 아이콘은 에셋에 포함되어 있으므로 그대로 렌더
            Image(toast.type.iconName)
                .frame(width: 32, height: 32)

            Text(toast.message)
                .font(.body2Medium)
                .foregroundStyle(Color.gray50)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 56)
        .padding(.horizontal, .spacing16)
        .background(Color.systemToast, in: RoundedRectangle(cornerRadius: .roundedLg))
    }
}

// MARK: - Host Modifier

private struct BoatToastHostModifier: ViewModifier {
    let state: BoatToastState

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = state.current {
                    BoatToastView(toast: toast)
                        .padding(.horizontal, .spacing20)
                        .padding(.top, .spacing8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .id(toast.id)
                        // 새 토스트가 뜨면 id가 바뀌어 타이머 재시작
                        .task(id: toast.id) {
                            try? await Task.sleep(for: .seconds(3))
                            state.dismiss()
                        }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: state.current)
    }
}

extension View {
    /// 화면 최상위에 토스트 호스트를 부착한다. (루트 컨테이너에 1회 적용)
    func boatToastHost(_ state: BoatToastState) -> some View {
        modifier(BoatToastHostModifier(state: state))
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var toast = BoatToastState()

        var body: some View {
            VStack(spacing: 16) {
                Button("에러 토스트") { toast.showError("로그인이 취소되었습니다.") }
                Button("인포 토스트") { toast.show("무료 횟수 3회가 충전되었습니다.") }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray100)
            .boatToastHost(toast)
        }
    }
    return PreviewWrapper()
}
