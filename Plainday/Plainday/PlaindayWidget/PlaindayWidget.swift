import WidgetKit
import SwiftUI

// MARK: - Data the app shares (written by Plainday after every change)

struct DaySummary: Codable {
    struct Task: Codable { let t: String; let done: Bool; let star: Bool? }
    struct Event: Codable { let t: String; let when: String }
    struct Reminder: Codable { let t: String; let when: String; let overdue: Bool }
    let date: String
    let done: Int
    let total: Int
    let tasks: [Task]
    let events: [Event]
    let rems: [Reminder]
    let shop: Int
    let pal: String?

    var isToday: Bool {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return date == f.string(from: Date())
    }
    var left: Int { max(total - done, 0) }

    static let sample = DaySummary(
        date: "", done: 1, total: 4,
        tasks: [.init(t: "Reply to Maya", done: false, star: true),
                .init(t: "Take vitamins", done: false, star: false),
                .init(t: "Book an oil change", done: false, star: false),
                .init(t: "30-minute walk", done: true, star: false)],
        events: [.init(t: "Dinner with Sam", when: "Today · 7:00 PM"),
                 .init(t: "Dentist", when: "Tue, Nov 24 · 10:15 AM")],
        rems: [.init(t: "Pay the electric bill", when: "Today · 5:00 PM", overdue: false)],
        shop: 2, pal: "lavender")
}

enum Shared {
    static func load() -> DaySummary? {
        let group = Bundle.main.object(forInfoDictionaryKey: "PlaindayAppGroup") as? String ?? ""
        guard !group.isEmpty,
              let data = UserDefaults(suiteName: group)?.data(forKey: "summary") else { return nil }
        return try? JSONDecoder().decode(DaySummary.self, from: data)
    }
}

// MARK: - Timeline

struct DayEntry: TimelineEntry {
    let date: Date
    let summary: DaySummary?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry { DayEntry(date: Date(), summary: .sample) }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        completion(DayEntry(date: Date(), summary: Shared.load() ?? .sample))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let entry = DayEntry(date: Date(), summary: Shared.load())
        // Refresh every 30 minutes, and right after midnight so the date flips.
        let soon = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        completion(Timeline(entries: [entry], policy: .after(min(soon, midnight))))
    }
}

// MARK: - Colours (match the app's pastel palettes)

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

struct Palette {
    let band: Color
    let pri: Color
    static let ink = Color(hex: 0x2B2840)
    static let mute = Color(hex: 0x6F6A88)
    static let coral = Color(hex: 0xD4583F)

    static func named(_ name: String?) -> Palette {
        switch name {
        case "mint":  return Palette(band: Color(hex: 0xC9F0DC), pri: Color(hex: 0x3A8F6B))
        case "peach": return Palette(band: Color(hex: 0xFFD9C7), pri: Color(hex: 0xC4613F))
        case "sky":   return Palette(band: Color(hex: 0xCFE3FF), pri: Color(hex: 0x4774C4))
        default:      return Palette(band: Color(hex: 0xD9D1FF), pri: Color(hex: 0x7A68D8))
        }
    }
}

extension View {
    @ViewBuilder func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(color, for: .widget)
        } else {
            background(color)
        }
    }
}

// MARK: - Views

struct TodayView: View {
    @Environment(\.widgetFamily) var family
    let entry: DayEntry

    var body: some View {
        let s = entry.summary
        let pal = Palette.named(s?.pal)
        Group {
            switch family {
            case .accessoryInline:      InlineView(s: s)
            case .accessoryCircular:    CircularView(s: s)
            case .accessoryRectangular: RectangularView(s: s)
            case .systemMedium:         MediumView(s: s, pal: pal)
            case .systemLarge:          LargeView(s: s, pal: pal)
            default:                    SmallView(s: s, pal: pal)
            }
        }
        .widgetBackground(family.isAccessory ? .clear : pal.band)
    }
}

extension WidgetFamily {
    var isAccessory: Bool {
        switch self {
        case .accessoryInline, .accessoryCircular, .accessoryRectangular: return true
        default: return false
        }
    }
}

struct DateHeader: View {
    var big: Bool = true
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Date(), format: .dateTime.weekday(.wide))
                .font(.caption.weight(.semibold))
                .foregroundColor(Palette.mute)
            Text(Date(), format: .dateTime.month(.abbreviated).day())
                .font(.system(size: big ? 24 : 20, weight: .heavy, design: .rounded))
                .foregroundColor(Palette.ink)
        }
    }
}

struct DayProgress: View {
    let s: DaySummary?
    let pal: Palette
    var body: some View {
        let done = (s?.isToday ?? false) ? s!.done : 0
        let total = (s?.isToday ?? false) ? s!.total : (s?.total ?? 0)
        VStack(alignment: .leading, spacing: 4) {
            Text("\(done) of \(total) done")
                .font(.caption.weight(.semibold))
                .foregroundColor(Palette.ink)
            ProgressView(value: Double(done), total: Double(max(total, 1)))
                .tint(pal.pri)
        }
    }
}

struct TaskRow: View {
    let task: DaySummary.Task
    let pal: Palette
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: task.done ? "checkmark.square.fill" : "square")
                .foregroundColor(task.done ? pal.pri : Palette.mute)
            Text(task.t)
                .strikethrough(task.done)
                .foregroundColor(task.done ? Palette.mute : Palette.ink)
                .lineLimit(1)
            if task.star == true && !task.done {
                Image(systemName: "star.fill").font(.caption2).foregroundColor(Palette.coral)
            }
        }
        .font(.subheadline)
    }
}

struct Empty: View {
    let text: String
    var body: some View {
        Text(text).font(.caption).foregroundColor(Palette.mute)
    }
}

struct SmallView: View {
    let s: DaySummary?
    let pal: Palette
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            DateHeader()
            Spacer(minLength: 0)
            DayProgress(s: s, pal: pal)
            if let e = s?.events.first {
                VStack(alignment: .leading, spacing: 0) {
                    Text(e.t).font(.caption.weight(.bold)).foregroundColor(Palette.ink).lineLimit(1)
                    Text(e.when).font(.caption2).foregroundColor(Palette.mute).lineLimit(1)
                }
            } else if s == nil {
                Empty(text: "Open Plainday")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct MediumView: View {
    let s: DaySummary?
    let pal: Palette
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                DateHeader()
                Spacer(minLength: 0)
                DayProgress(s: s, pal: pal)
            }
            .frame(width: 110, alignment: .leading)
            VStack(alignment: .leading, spacing: 5) {
                if let s = s, s.isToday, !s.tasks.isEmpty {
                    ForEach(Array(s.tasks.prefix(4).enumerated()), id: \.offset) { _, t in TaskRow(task: t, pal: pal) }
                } else {
                    Empty(text: s == nil ? "Open Plainday to set up your day." : "Open Plainday to start today.")
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SectionTitle: View {
    let title: String
    let pal: Palette
    var body: some View {
        Text(title).font(.caption.weight(.bold)).foregroundColor(pal.pri)
    }
}

struct LargeView: View {
    let s: DaySummary?
    let pal: Palette
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom) {
                DateHeader()
                Spacer()
                DayProgress(s: s, pal: pal).frame(width: 120)
            }
            SectionTitle(title: "Tasks", pal: pal)
            if let s = s, s.isToday, !s.tasks.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(s.tasks.prefix(5).enumerated()), id: \.offset) { _, t in TaskRow(task: t, pal: pal) }
                }
            } else {
                Empty(text: "Open Plainday to start today.")
            }
            if let events = s?.events, !events.isEmpty {
                SectionTitle(title: "Next up", pal: pal)
                ForEach(Array(events.prefix(2).enumerated()), id: \.offset) { _, e in
                    HStack {
                        Text(e.t).font(.subheadline.weight(.semibold)).foregroundColor(Palette.ink).lineLimit(1)
                        Spacer()
                        Text(e.when).font(.caption).foregroundColor(Palette.mute).lineLimit(1)
                    }
                }
            }
            if let rems = s?.rems, !rems.isEmpty {
                SectionTitle(title: "Reminders", pal: pal)
                ForEach(Array(rems.prefix(2).enumerated()), id: \.offset) { _, r in
                    HStack {
                        Text(r.t).font(.subheadline).foregroundColor(Palette.ink).lineLimit(1)
                        Spacer()
                        Text(r.when).font(.caption)
                            .foregroundColor(r.overdue ? Palette.coral : Palette.mute).lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// Lock Screen

struct RectangularView: View {
    let s: DaySummary?
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let e = s?.events.first {
                Text(e.t).font(.headline).lineLimit(1)
                Text(e.when).font(.caption).lineLimit(1)
            } else {
                Text("Plainday").font(.headline)
            }
            if let s = s, s.isToday {
                Text(s.left == 0 ? "All tasks done" : "\(s.left) task\(s.left == 1 ? "" : "s") left")
                    .font(.caption).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CircularView: View {
    let s: DaySummary?
    var body: some View {
        let total = Double(max(s?.total ?? 0, 1))
        let done = Double((s?.isToday ?? false) ? s!.done : 0)
        Gauge(value: done, in: 0...total) {
            Image(systemName: "checkmark")
        } currentValueLabel: {
            Text("\((s?.isToday ?? false) ? s!.left : (s?.total ?? 0))")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}

struct InlineView: View {
    let s: DaySummary?
    var body: some View {
        if let s = s, let e = s.events.first {
            Text("\(s.left) left · \(e.t)")
        } else if let s = s {
            Text("\(s.left) tasks left today")
        } else {
            Text("Plainday")
        }
    }
}

// MARK: - Widget

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PlaindayToday", provider: Provider()) { entry in
            TodayView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("Your tasks, next event and reminders at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

@main
struct PlaindayWidgets: WidgetBundle {
    var body: some Widget {
        TodayWidget()
    }
}
