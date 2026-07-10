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

    var body: some View {
        VStack(spacing: 0) {
            DatePicker("", selection: $date, displayedComponents: .date)
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
