//
//  PurchaseDatePickerSheet.swift
//  BOAT
//
//  구매일 선택 캘린더 시트. 별도의 취소/확인 버튼 없이, 날짜를 탭하는 즉시 반영되고
//  호출부에서 시트를 닫는다(스크림 탭으로 내리면 아무 변경 없이 취소).
//
//  SwiftUI DatePicker(.graphical) 대신 UICalendarView를 쓰는 이유:
//  1) DatePicker는 onChange(값 변경)로만 선택을 알 수 있어, 이미 선택된 날짜를 다시 탭하면
//     아무 일도 일어나지 않았다. UICalendarView는 델리게이트가 탭마다 호출되므로
//     같은 날짜를 다시 탭해도 시트를 닫을 수 있다.
//  2) DatePicker(.graphical)는 주어진 높이에 맞춰 내용이 잘리는 경우가 있었다.
//     UICalendarView는 intrinsic 높이를 보고해 필요한 만큼만 차지한다(sizeThatFits).
//

import SwiftUI
import UIKit

struct PurchaseDatePickerSheet: View {

    /// 현재 입력된 구매일("yyyy.MM.dd"). 비어 있으면 오늘로 시작한다.
    /// 시트를 다시 열었을 때 이전에 고른 날짜가 그대로 선택되어 있어야 하므로 반드시 전달한다.
    var selected: String = ""
    let onSelect: (String) -> Void

    private static let displayFormat = "yyyy.MM.dd"

    /// 오늘 이후(미래) 날짜는 선택 불가. 상한을 정확한 현재 시각(Date())으로 두면 캘린더에서
    /// 오늘 당일까지 비활성화되는 것처럼 보이는 문제가 있어, 오늘의 끝(23:59:59)까지로 잡는다.
    private var upperBound: Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: startOfToday)!.addingTimeInterval(-1)
    }

    private var initialDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = Self.displayFormat
        return formatter.date(from: selected) ?? Date()
    }

    var body: some View {
        // Spacer를 두면 콘텐츠 기준으로 높이를 잡는 BoatBottomSheetContainer 안에서
        // 남은 공간을 모두 밀어내며 시트가 화면 전체로 커진다 — 넣지 않는다.
        CalendarView(
            initialDate: initialDate,
            upperBound: upperBound,
            onPick: { date in
                let formatter = DateFormatter()
                formatter.dateFormat = Self.displayFormat
                onSelect(formatter.string(from: date))
            }
        )
        .padding(.horizontal, .spacing8)
        .padding(.top, .spacing8)
        .padding(.bottom, .spacing8)
    }
}

// MARK: - UICalendarView 래퍼

private struct CalendarView: UIViewRepresentable {

    let initialDate: Date
    let upperBound: Date
    let onPick: (Date) -> Void

    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = Calendar(identifier: .gregorian)
        view.locale = Locale(identifier: "ko_KR")
        view.tintColor = UIColor(Color.brandPrimary)
        view.backgroundColor = .clear
        // 날짜 아래 점(데코레이션)은 쓰지 않는다.
        view.wantsDateDecorations = false
        view.availableDateRange = DateInterval(start: .distantPast, end: upperBound)

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        selection.setSelected(context.coordinator.components(for: initialDate), animated: false)
        view.selectionBehavior = selection

        return view
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        context.coordinator.onPick = onPick
        context.coordinator.lastSelected = initialDate
    }

    /// UICalendarView가 원하는 만큼의 높이만 차지하도록 intrinsic 높이를 그대로 보고한다.
    /// (고정 높이를 주면 하단이 잘리거나 반대로 빈 공간이 남는다)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UICalendarView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.intrinsicContentSize.width
        let fitted = uiView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: width, height: fitted.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(initialDate: initialDate, onPick: onPick)
    }

    final class Coordinator: NSObject, UICalendarSelectionSingleDateDelegate {

        var onPick: (Date) -> Void
        /// 직전 선택 날짜 — 이미 선택된 날짜를 다시 탭하면 UICalendarView가 "선택 해제"로
        /// 보고(dateComponents == nil)하는데, 그때도 이 값으로 확정 처리해 시트를 닫는다.
        var lastSelected: Date

        init(initialDate: Date, onPick: @escaping (Date) -> Void) {
            self.lastSelected = initialDate
            self.onPick = onPick
        }

        func components(for date: Date) -> DateComponents {
            Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        }

        func dateSelection(
            _ selection: UICalendarSelectionSingleDate,
            didSelectDate dateComponents: DateComponents?
        ) {
            // nil = 이미 선택돼 있던 날짜를 다시 탭해 해제된 경우 → 기존 선택을 그대로 확정한다.
            guard let dateComponents,
                  let date = Calendar(identifier: .gregorian).date(from: dateComponents) else {
                onPick(lastSelected)
                return
            }
            lastSelected = date
            onPick(date)
        }
    }
}
