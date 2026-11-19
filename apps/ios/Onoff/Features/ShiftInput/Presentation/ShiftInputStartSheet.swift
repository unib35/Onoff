// REQ-009 · REQ-038 · UI-IOS-14a — 근무 입력 시작 시트. 1.0은 직접 넣기 키패드 · 칠하기를 켜고
// 사진 보며(22c)와 한 번에 채우기 순서 반복(22a)을 켠다. 사진 인식 · 글자 · 병동 받기(1.2 · 2.0) · 지난달 복사(DEC-014) ·
// 「지난번 방법으로 바로 열기」는 숨긴다.
import SwiftUI

struct ShiftInputStartSheet: View {
    @State var viewModel: ShiftInputStartViewModel
    let onMethod: (ShiftInputMethod) -> Void
    let onRepeat: () -> Void
    /// 「사진 보며」 — 22c
    let onPhoto: () -> Void

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
                Button { onMethod(.keypad) } label: {
                    MethodCard(title: "키패드", detail: "하루씩 · 누르면 다음 날")
                }
                .buttonStyle(.plain)
                Button { onMethod(.paint) } label: {
                    MethodCard(title: "칠하기", detail: "끌어서 여러 날")
                }
                .buttonStyle(.plain)
                // 「글자」(타자 · 붙여넣기)는 1.0에서 숨김(REQ-038)
                Button(action: onPhoto) {
                    MethodCard(title: "사진 보며", detail: "사진 띄우고 키패드")
                }
                .buttonStyle(.plain)
            }

            Text("한 번에 채우기").onoffText(12, .bold).foregroundStyle(OnoffColor.textTertiary)
            HStack(spacing: 6) {
                Button(action: onRepeat) {
                    Text("순서 반복").onoffText(13, .bold)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(OnoffColor.background, in: RoundedRectangle(cornerRadius: OnoffRadius.button))
                }
                .buttonStyle(.plain)
                // 원본 14a는 두 칸(지난달 복사 · DEC-014로 나중) — 자리만 맞춘다
                Color.clear.frame(maxWidth: .infinity, maxHeight: 40)
            }
        }
        .foregroundStyle(OnoffColor.ink)
        .padding(.horizontal, 18)
        .padding(.top, 28)
        .padding(.bottom, 36)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationDetents([.height(394)])
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
