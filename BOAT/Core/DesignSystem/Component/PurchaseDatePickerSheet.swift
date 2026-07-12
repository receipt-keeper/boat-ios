//
//  PurchaseDatePickerSheet.swift
//  BOAT
//
//  구매일 선택 캘린더 시트. 별도의 취소/확인 버튼 없이, 날짜를 탭하는 즉시 반영되고
//  호출부에서 시트를 닫는다(스와이프로 내리면 아무 변경 없이 취소).
//

import SwiftUI

struct PurchaseDatePickerSheet: View {
    let onSelect: (String) -> Void

    @State private var date = Date()

    // 오늘 이후(미래) 날짜는 선택 불가. 상한을 정확한 현재 시각(Date())으로 두면 그래픽 캘린더에서
    // 오늘 당일까지 비활성화되는 것처럼 보이는 문제가 있어, 오늘의 끝(23:59:59)까지로 잡는다.
    private var upperBound: Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: startOfToday)!.addingTimeInterval(-1)
    }

    var body: some View {
        VStack(spacing: 0) {
            DatePicker("", selection: $date, in: ...upperBound, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Color.brandPrimary)
                .padding(.horizontal, .spacing12)
                .padding(.top, .spacing16)
                .onChange(of: date) { _, newDate in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy.MM.dd"
                    onSelect(formatter.string(from: newDate))
                }

            Spacer()
        }
        .presentationBackground(Color.colorWhite)
    }
}
