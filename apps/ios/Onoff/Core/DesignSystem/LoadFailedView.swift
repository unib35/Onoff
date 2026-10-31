// 불러오기 실패 — 오류를 삼키지 않고 다시 시도를 둔다(code.md). 원본에 이 경우의 화면 · 문구가 없어 확인 필요(PR #3 본문).
import SwiftUI

struct LoadFailedView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: OnoffSpace.l) {
            Text("불러오지 못했어요").onoffText(15, .semibold)
            Button(action: retry) {
                Text("다시 시도")
                    .onoffText(14, .bold)
                    .foregroundStyle(OnoffColor.onInk)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(OnoffColor.ink, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(OnoffColor.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, OnoffSpace.xxl)
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: OnoffRadius.card))
    }
}
