import SwiftUI

struct MarkEditor: View {
    @EnvironmentObject var store: MarkStore
    let day: Date
    var onClose: () -> Void
    private let cal = Calendar.current

    private let presets: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    @State private var existing: DateMark? = nil
    @State private var label = ""
    @State private var repeatRule: MarkRepeat = .none
    @State private var shape: MarkShape = .circle
    @State private var filled = true
    @State private var color: Color = .orange

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderless)
                Text(dateTitle).font(.headline)
                Spacer()
            }

            TextField("Label (e.g. Mom's Birthday)", text: $label)
                .textFieldStyle(.roundedBorder)

            Picker("", selection: $repeatRule) {
                ForEach(MarkRepeat.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            HStack(spacing: 8) {
                Picker("", selection: $shape) {
                    Image(systemName: "circle").tag(MarkShape.circle)
                    Image(systemName: "square").tag(MarkShape.roundedRect)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 84)

                Picker("", selection: $filled) {
                    Text("Fill").tag(true)
                    Text("Outline").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            HStack(spacing: 7) {
                ForEach(presets, id: \.self) { c in
                    Circle()
                        .fill(c)
                        .frame(width: 18, height: 18)
                        .overlay {
                            if c.hexString == color.hexString {
                                Circle().strokeBorder(.primary, lineWidth: 2)
                            }
                        }
                        .onTapGesture { color = c }
                }
                ColorPicker("", selection: $color).labelsHidden()
            }

            HStack {
                if existing != nil {
                    Button("Clear", role: .destructive) { clear() }
                }
                Spacer()
                Button("Clear All") { store.clearAll(); onClose() }
                    .foregroundStyle(.secondary)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
            }
            .font(.callout)
        }
        .padding(12)
        .frame(width: 260)
        .onAppear(perform: loadExisting)
    }

    // MARK: Actions

    private func loadExisting() {
        guard let m = store.mark(on: day, cal: cal) else { return }
        existing = m
        label = m.label
        repeatRule = m.repeatRule
        shape = m.shape
        filled = m.filled
        color = Color(hex: m.colorHex)
    }

    private func save() {
        let c = cal.dateComponents([.year, .month, .day], from: day)
        var m = existing ?? DateMark(year: c.year!, month: c.month!, day: c.day!,
                                     label: "", repeatRule: .none, shape: .circle,
                                     filled: true, colorHex: "")
        m.label = label
        m.repeatRule = repeatRule
        m.shape = shape
        m.filled = filled
        m.colorHex = color.hexString
        store.upsert(m)
        onClose()
    }

    private func clear() {
        if let existing { store.remove(id: existing.id) }
        onClose()
    }

    private var dateTitle: String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE MMM d yyyy")
        return f.string(from: day)
    }
}
