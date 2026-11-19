// REQ-009 · REQ-038 · UI-IOS-14a — 근무 입력 시작 시트. 1.0은 직접 넣기 키패드만 켜고
// 칠하기 · 순서 반복(다음 이슈) · 사진 · 글자 · 병동 받기(1.2 · 2.0) · 지난달 복사(DEC-014) · 「지난번 방법으로 바로 열기」는 숨긴다.
import SwiftUI

struct ShiftInputStartSheet: View {
    @State var viewModel: ShiftInputStartViewModel
    let onKeypad: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: OnoffSpace.l) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(viewModel.month)월 근무 넣기").onoffText(22, .bold)
                Spacer()
                if let count = viewModel.unregisteredDays {
                    Text("미등록 \(count)일").onoffText(13, numeric: true).foregroundStyle(OnoffColor.textSecondary)
                }
            }

            Text("직접 넣기 · 중간에 바꿀 수 있어요").onoffText(12, .bold).foregroundStyle(OnoffColor.textTertiary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                Button(action: onKeypad) {
                    MethodCard(title: "키패드", detail: "하루씩 · 누르면 다음 날")
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(OnoffColor.ink)
        .padding(.horizontal, 18)
        .padding(.top, 28)
        .padding(.bottom, 36)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .presentationBackground(OnoffColor.card)
        .task { await viewModel.load() }
    }
}

/// 14a 「직접 넣기」 카드
private struct MethodCard: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).onoffText(15, .heavy)
            Text(detail).onoffText(12).foregroundStyle(OnoffColor.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(OnoffSpace.l)
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(OnoffColor.line, lineWidth: 1))
        .contentShape(Rectangle())
    }
}
