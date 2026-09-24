import SwiftUI

struct OptionalRatingPicker: View {
    let title: String
    @Binding var value: Int?

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Menu {
                Button("Not set") { value = nil }
                ForEach(1...5, id: \.self) { rating in
                    Button("\(rating) / 5") { value = rating }
                }
            } label: {
                Text(value.map { "\($0) / 5" } ?? "Optional")
                    .foregroundStyle(value == nil ? .secondary : .primary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct RatingGroup: View {
    @Binding var focus: Int?
    @Binding var energy: Int?
    @Binding var mood: Int?
    @Binding var difficulty: Int?

    var body: some View {
        OptionalRatingPicker(title: "Focus", value: $focus)
        OptionalRatingPicker(title: "Energy", value: $energy)
        OptionalRatingPicker(title: "Mood", value: $mood)
        OptionalRatingPicker(title: "Difficulty", value: $difficulty)
    }
}
