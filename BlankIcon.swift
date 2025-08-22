import SwiftUI
import CoreGraphics

// MARK: - Fragment Glyph System
enum FragmentGlyph: String, CaseIterable {
    case analyzer, download, commit, refactor
}

enum GlyphMorphState: Equatable, CaseIterable {
    case idle
    case active
    case processing
    case error

    var description: String {
        switch self {
        case .idle: return "idle"
        case .active: return "active"
        case .processing: return "processing"
        case .error: return "error"
        }
    }
}

// MARK: - GlyphIcon Protocol
protocol GlyphIcon: View {
    var glyph: FragmentGlyph { get }
    var state: GlyphMorphState { get set }
    var size: CGFloat { get set }
}

// MARK: - Polygon Shape
struct Polygon: Shape {
    var sides: Int
    var cornerRadius: CGFloat = 0

    var animatableData: CGFloat {
        get { cornerRadius }
        set { cornerRadius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard sides >= 3 else { return Path() }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - cornerRadius

        let angle = 2 * .pi / CGFloat(sides)
        let vertices: [CGPoint] = (0..<sides).map { i in
            let theta = angle * CGFloat(i) - .pi / 2
            return CGPoint(
                x: center.x + cos(theta) * radius,
                y: center.y + sin(theta) * radius
            )
        }

        var path = Path()
        for i in 0..<sides {
            let prev = vertices[(i - 1 + sides) % sides]
            let current = vertices[i]
            let next = vertices[(i + 1) % sides]

            let prevVector = CGVector(dx: current.x - prev.x, dy: current.y - prev.y)
            let nextVector = CGVector(dx: next.x - current.x, dy: next.y - current.y)

            let prevLen = sqrt(prevVector.dx * prevVector.dx + prevVector.dy * prevVector.dy)
            let nextLen = sqrt(nextVector.dx * nextVector.dx + nextVector.dy * nextVector.dy)

            let prevInset = CGPoint(
                x: current.x - (cornerRadius * prevVector.dx / prevLen),
                y: current.y - (cornerRadius * prevVector.dy / prevLen)
            )
            let nextInset = CGPoint(
                x: current.x + (cornerRadius * nextVector.dx / nextLen),
                y: current.y + (cornerRadius * nextVector.dy / nextLen)
            )

            if i == 0 {
                path.move(to: prevInset)
            } else {
                path.addLine(to: prevInset)
            }

            path.addQuadCurve(to: nextInset, control: current)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Affinity Profile Environment
struct AffinityProfile {
    var gradientColors: [Color]
    var gradientStart: UnitPoint = .topLeading
    var gradientEnd: UnitPoint = .bottomTrailing
    var shadowColor: Color
    var glowIntensity: CGFloat
    var glowColor: Color

    init(
        gradientColors: [Color],
        gradientStart: UnitPoint = .topLeading,
        gradientEnd: UnitPoint = .bottomTrailing,
        shadowColor: Color = .black.opacity(0.2),
        glowIntensity: CGFloat = 0.3,
        glowColor: Color = .white
    ) {
        self.gradientColors = gradientColors
        self.gradientStart = gradientStart
        self.gradientEnd = gradientEnd
        self.shadowColor = shadowColor
        self.glowIntensity = glowIntensity
        self.glowColor = glowColor
    }

    static let defaultTheme = AffinityProfile(
        gradientColors: [.blue, .purple],
        shadowColor: .purple.opacity(0.3),
        glowIntensity: 0.4,
        glowColor: .purple.opacity(0.6)
    )

    static let ocean = AffinityProfile(
        gradientColors: [.cyan, .blue],
        shadowColor: .blue.opacity(0.3),
        glowIntensity: 0.4,
        glowColor: .blue.opacity(0.5)
    )

    static let sunset = AffinityProfile(
        gradientColors: [.orange, .pink, .purple],
        gradientStart: .top,
        gradientEnd: .bottom,
        shadowColor: .orange.opacity(0.4),
        glowIntensity: 0.5,
        glowColor: .pink.opacity(0.7)
    )

    static let forest = AffinityProfile(
        gradientColors: [.green, .mint],
        shadowColor: .green.opacity(0.3),
        glowIntensity: 0.3,
        glowColor: .mint.opacity(0.5)
    )

    static let error = AffinityProfile(
        gradientColors: [.red, .orange],
        shadowColor: .red.opacity(0.5),
        glowIntensity: 0.6,
        glowColor: .red.opacity(0.8)
    )
}

private struct AffinityProfileKey: EnvironmentKey {
    static let defaultValue = AffinityProfile.defaultTheme
}

extension EnvironmentValues {
    var affinityProfile: AffinityProfile {
        get { self[AffinityProfileKey.self] }
        set { self[AffinityProfileKey.self] = newValue }
    }
}

// MARK: - FragmentGlyphIcon (Symbolic System)
struct FragmentGlyphIcon: GlyphIcon {
    var glyph: FragmentGlyph
    @State var state: GlyphMorphState
    var size: CGFloat = 28
    var enableHaptics: Bool = true
    var animationDuration: Double = 0.35
    var animationOffset: Double = 0

    @Environment(\.affinityProfile) private var affinity
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @State private var morphProgress: CGFloat = 1.0
    @State private var isHovering = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var innerPolygonScale: CGFloat = 1.0
    @State private var outerCircleScale: CGFloat = 1.0
    @State private var glowScale: CGFloat = 1.0

    // --- Symbol logic ---
    private var currentProfile: AffinityProfile {
        switch state {
        case .error: return .error
        default: return affinity
        }
    }

    private var mainGradient: LinearGradient {
        LinearGradient(
            colors: currentProfile.gradientColors,
            startPoint: currentProfile.gradientStart,
            endPoint: currentProfile.gradientEnd
        )
    }

    private var glowGradient: LinearGradient {
        LinearGradient(
            colors: [currentProfile.glowColor.opacity(currentProfile.glowIntensity), currentProfile.glowColor.opacity(0)],
            startPoint: .center,
            endPoint: .center
        )
    }

    private var isCompact: Bool {
        hSizeClass == .compact
    }

    private var adjustedSize: CGFloat {
        isCompact ? size * 0.8 : size
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        a + (b - a) * morphProgress
    }

    // Symbol-specific logic
    private var polygonSides: Int {
        switch glyph {
        case .analyzer: return state == .error ? 3 : 4
        case .download: return 6
        case .commit: return 5
        case .refactor: return 8
        }
    }

    private var polygonCornerRadius: CGFloat {
        switch state {
        case .processing: return lerp(0, adjustedSize * 0.05)
        case .error: return lerp(adjustedSize * 0.05, adjustedSize * 0.15)
        default: return lerp(0, 0)
        }
    }

    private var polygonOffset: CGSize {
        switch glyph {
        case .analyzer:
            switch state {
            case .idle: return CGSize(width: adjustedSize * 0.29, height: adjustedSize * 0.29)
            case .active: return CGSize(width: adjustedSize * 0.21, height: adjustedSize * 0.21)
            case .processing: return CGSize(width: adjustedSize * 0.25, height: adjustedSize * 0.25)
            case .error: return CGSize(width: adjustedSize * 0.32, height: adjustedSize * 0.32)
            }
        case .download: return CGSize(width: adjustedSize * 0.18, height: adjustedSize * 0.32)
        case .commit: return CGSize(width: adjustedSize * 0.25, height: adjustedSize * 0.18)
        case .refactor: return CGSize(width: adjustedSize * 0.22, height: adjustedSize * 0.22)
        }
    }

    private var polygonRotation: Double {
        switch state {
        case .processing:
            return Double(Date().timeIntervalSinceReferenceDate * 120).truncatingRemainder(dividingBy: 360)
        case .idle: return 45
        case .active: return 90
        case .error: return 0
        }
    }

    private var shadowRadius: CGFloat {
        switch state {
        case .active: return 6
        case .processing: return 4
        case .error: return 8
        default: return 2
        }
    }

    private var shadowYOffset: CGFloat {
        switch state {
        case .active: return 3
        case .processing: return 2
        case .error: return 4
        default: return 1
        }
    }

    // --- Body ---
    var body: some View {
        ZStack {
            // Background glow effect
            if currentProfile.glowIntensity > 0 {
                Circle()
                    .fill(glowGradient)
                    .frame(width: adjustedSize * 0.86, height: adjustedSize * 0.86)
                    .blur(radius: (currentProfile.glowIntensity * 4) * glowScale)
                    .scaleEffect(outerCircleScale * 1.2 * glowScale)
                    .animation(
                        .easeInOut(duration: animationDuration * 1.5).delay(animationOffset * 0.1),
                        value: state
                    )
                    .animation(
                        .easeInOut(duration: 1.2).delay(animationOffset * 0.1).repeatForever(autoreverses: true),
                        value: glowScale
                    )
            }

            // Main circle
            Circle()
                .stroke(mainGradient, lineWidth: adjustedSize * 0.06)
                .frame(width: adjustedSize * 0.86, height: adjustedSize * 0.86)
                .scaleEffect(outerCircleScale)
                .opacity(1.0)
                .shadow(
                    color: currentProfile.shadowColor,
                    radius: shadowRadius,
                    x: 0,
                    y: shadowYOffset
                )
                .animation(
                    .spring(response: animationDuration, dampingFraction: 0.7, blendDuration: animationDuration),
                    value: state
                )
                .animation(
                    .easeInOut(duration: animationDuration * 0.8),
                    value: isHovering
                )

            // Inner polygon
            Polygon(sides: polygonSides, cornerRadius: polygonCornerRadius)
                .fill(mainGradient)
                .frame(width: adjustedSize * 0.21, height: adjustedSize * 0.21)
                .scaleEffect(innerPolygonScale)
                .offset(x: polygonOffset.width, y: polygonOffset.height)
                .rotationEffect(.degrees(polygonRotation))
                .animation(
                    .spring(response: animationDuration, dampingFraction: 0.8, blendDuration: animationDuration),
                    value: state
                )
        }
        .frame(width: adjustedSize, height: adjustedSize)
        .contentShape(Circle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onChange(of: state) { _, newState in
            handleStateChange(newState)
            animateForState(newState)
        }
        .onAppear {
            setupAnimations()
            animateForState(state)
        }
        .accessibilityLabel("\(glyph.rawValue.capitalized) glyph icon")
        .accessibilityValue("State: \(state.description)")
        .accessibilityHint("Indicates the current status")
        .accessibilityAddTraits(state == .active ? .isSelected : [])
    }

    // --- Animation Handling ---

    private func handleStateChange(_ newState: GlyphMorphState) {
        #if os(iOS)
        if enableHaptics {
            switch newState {
            case .active:
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            case .error:
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.error)
            default:
                break
            }
        } else {
            UIAccessibility.post(notification: .announcement, argument: "State changed to \(newState.description)")
        }
        #endif
    }

    private func setupAnimations() {
        pulseScale = 1.0
        innerPolygonScale = 1.0
        outerCircleScale = 1.0
        glowScale = 1.0
        morphProgress = 1.0
    }

    private func animateForState(_ newState: GlyphMorphState) {
        innerPolygonScale = 1.0
        outerCircleScale = 1.0
        pulseScale = 1.0
        glowScale = 1.0
        morphProgress = 0.0

        withAnimation(.easeInOut(duration: animationDuration * 1.2).delay(animationOffset * 0.1)) {
            morphProgress = 1.0
            switch newState {
            case .active:
                outerCircleScale = 1.08
                innerPolygonScale = 1.05
            case .processing:
                pulseScale = 1.15
            case .error:
                outerCircleScale = 0.92
                innerPolygonScale = 0.95
            case .idle:
                break
            }
        }

        switch newState {
        case .processing:
            withAnimation(.easeInOut(duration: 1.0).delay(animationOffset * 0.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        default:
            pulseScale = 1.0
        }
    }
}

// MARK: - Theme Editor Integration (Stub)
struct AffinityProfileEditor: View {
    @Binding var profile: AffinityProfile

    var body: some View {
        VStack {
            Text("Theme Editor (Stub)")
            // Add controls for gradient, glow, shadow, etc.
        }
    }
}

// MARK: - Previews
#Preview("All States - Light") {
    ScrollView {
        VStack(spacing: 40) {
            ForEach(FragmentGlyph.allCases, id: \.self) { glyph in
                VStack(spacing: 15) {
                    Text("\(glyph.rawValue.capitalized) Glyph")
                        .font(.headline)
                        .foregroundColor(.primary)
                    HStack(spacing: 25) {
                        ForEach(GlyphMorphState.allCases, id: \.self) { state in
                            VStack {
                                FragmentGlyphIcon(glyph: glyph, state: state, size: 35)
                                Text(state.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
    .previewDisplayName("All States - Light")
    .preferredColorScheme(.light)
}

#Preview("All States - Dark") {
    ScrollView {
        VStack(spacing: 40) {
            ForEach(FragmentGlyph.allCases, id: \.self) { glyph in
                VStack(spacing: 15) {
                    Text("\(glyph.rawValue.capitalized) Glyph")
                        .font(.headline)
                        .foregroundColor(.primary)
                    HStack(spacing: 25) {
                        ForEach(GlyphMorphState.allCases, id: \.self) { state in
                            VStack {
                                FragmentGlyphIcon(glyph: glyph, state: state, size: 35)
                                Text(state.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
    .previewDisplayName("All States - Dark")
    .preferredColorScheme(.dark)
}

#Preview("Theme Editor") {
    @State var profile = AffinityProfile.defaultTheme
    AffinityProfileEditor(profile: $profile)
}

#Preview("Interactive Demo") {
    struct InteractiveDemo: View {
        @State private var currentGlyph: FragmentGlyph = .analyzer
        @State private var currentState: GlyphMorphState = .idle
        @State private var selectedThemeIndex: Int = 0
        @State private var animationSpeedMultiplier: CGFloat = 1.0

        let themes: [(name: String, profile: AffinityProfile)] = [
            ("Default", .defaultTheme),
            ("Ocean", .ocean),
            ("Sunset", .sunset),
            ("Forest", .forest),
            ("Error", .error)
        ]

        var body: some View {
            NavigationView {
                VStack(spacing: 30) {
                    Text("Fragment Glyph Configurator")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    FragmentGlyphIcon(
                        glyph: currentGlyph,
                        state: currentState,
                        size: 80,
                        animationDuration: 0.4 / animationSpeedMultiplier
                    )
                    .environment(\.affinityProfile, themes[selectedThemeIndex].profile)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Glyph")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Picker("Glyph", selection: $currentGlyph) {
                            ForEach(FragmentGlyph.allCases, id: \.self) { glyph in
                                Text(glyph.rawValue.capitalized).tag(glyph)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, -5)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("State")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Picker("State", selection: $currentState) {
                            ForEach(GlyphMorphState.allCases, id: \.self) { state in
                                Text(state.description.capitalized).tag(state)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, -5)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Theme")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Picker("Theme", selection: $selectedThemeIndex) {
                            ForEach(0..<themes.count, id: \.self) { index in
                                Text(themes[index].name).tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, -5)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Animation Speed: \(String(format: "%.1fx", animationSpeedMultiplier))")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Slider(value: $animationSpeedMultiplier, in: 0.5...2.0, step: 0.1)
                            .accentColor(themes[selectedThemeIndex].profile.gradientColors.first ?? .blue)
                    }

                    Spacer()
                }
                .padding()
                .navigationTitle("Glyph Customizer")
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
    }

    InteractiveDemo()
}