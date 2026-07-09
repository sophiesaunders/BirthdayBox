import SwiftUI

/// A self-contained emoji grid — no dependency on the system emoji keyboard or
/// Character Viewer, since bridging into those from SwiftUI proved unreliable
/// (dropped selections, inconsistent focus/dismiss behavior on macOS). This is
/// plain SwiftUI state, so it behaves identically and predictably everywhere.
enum EmojiCatalog {
    static let categories: [(name: String, emojis: [String])] = [
        ("Birthday", ["🎂", "🍰", "🧁", "🎉", "🎊", "🎈", "🎁", "🎀", "🪅", "🥳",
                      "✨", "🎆", "🎇", "🕯", "🍾", "🥂", "🎵", "🎶", "🌟", "🎠"]),
        ("Smileys", ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃",
                     "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙",
                     "😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔",
                     "🤐", "🤨", "😐", "😑", "😶", "😏", "😒", "🙄", "😬", "🤥",
                     "😌", "😔", "😪", "🤤", "😴", "😷", "🤒", "🤕", "🤢", "🤮",
                     "🥳", "🥸", "😎", "🤓", "🧐", "😕", "😟", "🙁", "😮", "😲"]),
        ("People", ["👋", "🤚", "🖐", "✋", "🖖", "👌", "🤌", "🤏", "✌️", "🤞",
                    "🤟", "🤘", "🤙", "👈", "👉", "👆", "🖕", "👇", "👍", "👎",
                    "✊", "👊", "🤛", "🤜", "👏", "🙌", "👐", "🤲", "🙏", "💪",
                    "🦾", "👶", "🧒", "👦", "👧", "🧑", "👱", "👨", "🧔", "👩",
                    "🧓", "👴", "👵", "🙋", "🙆", "🙅", "🕺", "💃", "🥳", "😻"]),
        ("Animals", ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯",
                     "🦁", "🐮", "🐷", "🐸", "🐵", "🐔", "🐧", "🐦", "🐤", "🦆",
                     "🦉", "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🐛", "🦋", "🐌",
                     "🐞", "🐢", "🐍", "🦖", "🐙", "🦀", "🐬", "🐳", "🐘", "🦒",
                     "🐫", "🦘", "🦥", "🦦", "🐇", "🐿", "🦔", "🐩", "🐈", "🐕"]),
        ("Food", ["🍏", "🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐",
                  "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑",
                  "🥦", "🌽", "🥕", "🧄", "🧅", "🥔", "🍞", "🥐", "🥯", "🧀",
                  "🥚", "🍳", "🥞", "🧇", "🥓", "🍔", "🍟", "🍕", "🌭", "🥪",
                  "🌮", "🌯", "🍜", "🍣", "🍩", "🍪", "🎂", "🍰", "🧁", "🍫"]),
        ("Activities", ["🎉", "🎊", "🎈", "🎁", "🎀", "🪅", "🎆", "🎇", "✨", "🎃",
                        "🎄", "🎋", "🎍", "🏆", "🥇", "🎯", "🎮", "🎲", "🎨", "🎭",
                        "🎤", "🎧", "🎸", "🎹", "🥁", "⚽️", "🏀", "🏈", "⚾️", "🎾",
                        "🏐", "🏓", "🎳", "⛳️", "🎣", "🥊", "🛹", "🎿", "🏄", "🚴"]),
        ("Travel", ["✈️", "🚗", "🚕", "🚙", "🚌", "🚎", "🏎", "🚓", "🚑", "🚒",
                    "🚲", "🛴", "🚀", "🛸", "⛵️", "🚤", "🚢", "🗽", "🗼", "🏰",
                    "🏖", "🏝", "🏔", "⛰", "🌋", "🏕", "🌄", "🌅", "🌃", "🌆"]),
        ("Objects", ["⌚️", "📱", "💻", "🖥", "🖨", "📷", "📹", "🎥", "📞", "☎️",
                     "📺", "📻", "⏰", "⏱", "🔋", "💡", "🔦", "🕯", "📚", "📖",
                     "✏️", "🖊", "🖌", "📌", "📎", "🔑", "🔒", "🔨", "🧰", "🧲"]),
        ("Symbols", ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔",
                     "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "☮️",
                     "✝️", "☪️", "🕉", "☸️", "✡️", "🔯", "🕎", "☯️", "⭐️", "🌟"])
    ]
}

struct EmojiPickerView: View {
    @Binding var selection: String
    let onSelect: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(EmojiCatalog.categories, id: \.name) { category in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(category.emojis, id: \.self) { emoji in
                                Button {
                                    selection = emoji
                                    onSelect()
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 24))
                                        .frame(width: 36, height: 36)
                                        .background(
                                            emoji == selection ? Color.accentColor.opacity(0.25) : Color.clear,
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(width: 340, height: 400)
    }
}

#Preview {
    EmojiPickerView(selection: .constant("🎂")) {}
}
