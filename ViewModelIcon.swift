import SwiftUI
import CoreGraphics
import Combine

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
public typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#endif

// MARK: - View Model State System
public enum ViewModelState: String, CaseIterable, Identifiable {
    case idle = "idle"
    case loading = "loading"
    case active = "active"
    case updating = "updating"
    case error = "error"
    case success = "success"
    
    public var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .idle: return "idle"
        case .loading: return "loading"
        case .active: return "active"
        case .updating: return "updating"
        case .error: return "error"
        case .success: return "success"
        }
    }
    
    // Animation characteristics for each state
    var animationStyle: AnimationStyle {
        switch self {
        case .idle: return .static
        case .loading: return .pulse
        case .active: return .glow
        case .updating: return .rotation
        case .error: return .shake
        case .success: return .bounce
        }
    }
}

public enum AnimationStyle {
    case static, pulse, glow, rotation, shake, bounce
}

// MARK: - Companion Affinity Integration
public extension CompanionAffinity {
    /// View model specific gradient variations
    var viewModelGradient: LinearGradient {
        switch self {
        case .lucis:
            return LinearGradient(colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.7), Color.white.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .orrin:
            return LinearGradient(colors: [Color.gray.opacity(0.7), Color.white.opacity(0.4), Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .caelo:
            return LinearGradient(colors: [Color.purple.opacity(0.8), Color.indigo.opacity(0.7), Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    /// State-specific animation physics
    func animationFor(state: ViewModelState) -> Animation {
        let baseAnimation: Animation
        
        switch state.animationStyle {
        case .static:
            baseAnimation = .easeInOut(duration: 0.3)
        case .pulse:
            baseAnimation = .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        case .glow:
            baseAnimation = .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        case .rotation:
            baseAnimation = .linear(duration: 2.0).repeatForever(autoreverses: false)
        case .shake:
            baseAnimation = .easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)
        case .bounce:
            baseAnimation = .spring(response: self.response, dampingFraction: self.damping * 0.5)
        }
        
        return baseAnimation
    }
}

// MARK: - View Model Affinity Profile
public struct ViewModelAffinityProfile {
    var gradientColors: [Color]
    var gradientStart: UnitPoint = .topLeading
    var gradientEnd: UnitPoint = .bottomTrailing
    var shadowColor: Color
    var glowIntensity: CGFloat
    var glowColor: Color
    var strokeWidth: CGFloat
    var animationIntensity: CGFloat
    
    init(
        gradientColors: [Color],
        gradientStart: UnitPoint = .topLeading,
        gradientEnd: UnitPoint = .bottomTrailing,
        shadowColor: Color = .black.opacity(0.2),
        glowIntensity: CGFloat = 0.3,
        glowColor: Color = .white,
        strokeWidth: CGFloat = 2.0,
        animationIntensity: CGFloat = 1.0
    ) {
        self.gradientColors = gradientColors
        self.gradientStart = gradientStart
        self.gradientEnd = gradientEnd
        self.shadowColor = shadowColor
        self.glowIntensity = glowIntensity
        self.glowColor = glowColor
        self.strokeWidth = strokeWidth
        self.animationIntensity = animationIntensity
    }
    
    // Predefined themes for view model states
    static let dataFlow = ViewModelAffinityProfile(
        gradientColors: [.blue, .cyan, .mint],
        shadowColor: .blue.opacity(0.3),
        glowIntensity: 0.5,
        glowColor: .cyan.opacity(0.7),
        strokeWidth: 2.5
    )
    
    static let processing = ViewModelAffinityProfile(
        gradientColors: [.orange, .yellow, .white],
        shadowColor: .orange.opacity(0.4),
        glowIntensity: 0.6,
        glowColor: .yellow.opacity(0.8),
        strokeWidth: 3.0,
        animationIntensity: 1.2
    )
    
    static let success = ViewModelAffinityProfile(
        gradientColors: [.green, .mint, .white],
        shadowColor: .green.opacity(0.3),
        glowIntensity: 0.4,
        glowColor: .mint.opacity(0.6),
        strokeWidth: 2.0
    )
    
    static let error = ViewModelAffinityProfile(
        gradientColors: [.red, .pink, .orange],
        shadowColor: .red.opacity(0.5),
        glowIntensity: 0.7,
        glowColor: .red.opacity(0.9),
        strokeWidth: 3.5,
        animationIntensity: 1.4
    )
    
    static let neutral = ViewModelAffinityProfile(
        gradientColors: [.gray, .white],
        shadowColor: .gray.opacity(0.2),
        glowIntensity: 0.2,
        glowColor: .white.opacity(0.4),
        strokeWidth: 1.5
    )
}

// MARK: - Data Flow Shape
struct DataFlowShape: Shape {
    var progress: CGFloat = 1.0
    var nodes: Int = 6
    var connectionStrength: CGFloat = 0.8
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 3
        
        var path = Path()
        
        // Create nodes in a circular pattern
        let angleStep = 2 * .pi / CGFloat(nodes)
        var nodePoints: [CGPoint] = []
        
        for i in 0..<nodes {
            let angle = angleStep * CGFloat(i) - .pi / 2
            let nodePoint = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            nodePoints.append(nodePoint)
            
            // Draw node circles
            let nodeSize = 8.0 * progress
            path.addEllipse(in: CGRect(
                x: nodePoint.x - nodeSize/2,
                y: nodePoint.y - nodeSize/2,
                width: nodeSize,
                height: nodeSize
            ))
        }
        
        // Connect nodes with curves
        for i in 0..<nodes {
            let startPoint = nodePoints[i]
            let endPoint = nodePoints[(i + 1) % nodes]
            let midPoint = CGPoint(
                x: (startPoint.x + endPoint.x) / 2,
                y: (startPoint.y + endPoint.y) / 2
            )
            
            // Create control point towards center for curved connections
            let controlPoint = CGPoint(
                x: midPoint.x + (center.x - midPoint.x) * connectionStrength * progress,
                y: midPoint.y + (center.y - midPoint.y) * connectionStrength * progress
            )
            
            path.move(to: startPoint)
            path.addQuadCurve(to: endPoint, control: controlPoint)
        }
        
        return path
    }
}

// MARK: - View Model Icon
public struct ViewModelIcon: View {
    @State public var state: ViewModelState
    public var size: CGFloat = 32
    public var affinity: CompanionAffinity = .lucis
    public var profile: ViewModelAffinityProfile = .dataFlow
    public var enableHaptics: Bool = true
    public var enableStateTransitions: Bool = true
    
    // Animation states
    @State private var isHovering = false
    @State private var animationScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var pulseOpacity: Double = 1.0
    @State private var glowScale: CGFloat = 1.0
    @State private var shakeOffset: CGSize = .zero
    @State private var dataFlowProgress: CGFloat = 1.0
    
    // Computed properties
    private var currentProfile: ViewModelAffinityProfile {
        switch state {
        case .error: return .error
        case .loading, .updating: return .processing
        case .success: return .success
        case .idle: return .neutral
        case .active: return profile
        }
    }
    
    private var mainGradient: LinearGradient {
        LinearGradient(
            colors: currentProfile.gradientColors,
            startPoint: currentProfile.gradientStart,
            endPoint: currentProfile.gradientEnd
        )
    }
    
    private var glowGradient: RadialGradient {
        RadialGradient(
            colors: [
                currentProfile.glowColor.opacity(currentProfile.glowIntensity),
                currentProfile.glowColor.opacity(0)
            ],
            center: .center,
            startRadius: 0,
            endRadius: size * 0.6
        )
    }
    
    private var iconScale: CGFloat {
        switch state {
        case .idle: return isHovering ? 1.05 : 1.0
        case .loading, .updating: return animationScale
        case .active: return 1.1
        case .error: return 0.95
        case .success: return 1.2 * animationScale
        }
    }
    
    private var iconOpacity: Double {
        switch state {
        case .loading: return pulseOpacity
        case .active: return 0.95
        case .error: return 0.9
        default: return 1.0
        }
    }
    
    public var body: some View {
        ZStack {
            // Background glow
            if currentProfile.glowIntensity > 0 {
                Circle()
                    .fill(glowGradient)
                    .frame(width: size * 1.4, height: size * 1.4)
                    .scaleEffect(glowScale)
                    .opacity(currentProfile.glowIntensity)
                    .blur(radius: 8)
            }
            
            // Main container circle
            Circle()
                .stroke(mainGradient, lineWidth: currentProfile.strokeWidth)
                .frame(width: size, height: size)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .shadow(
                    color: currentProfile.shadowColor,
                    radius: 4,
                    x: 0,
                    y: 2
                )
                .overlay(
                    // Data flow visualization
                    DataFlowShape(
                        progress: dataFlowProgress,
                        nodes: nodeCount,
                        connectionStrength: connectionStrength
                    )
                    .stroke(mainGradient, lineWidth: currentProfile.strokeWidth * 0.6)
                    .frame(width: size * 0.8, height: size * 0.8)
                    .scaleEffect(iconScale * 0.9)
                )
                .rotationEffect(.degrees(rotationAngle))
                .offset(shakeOffset)
        }
        .frame(width: size * 1.5, height: size * 1.5)
        .contentShape(Circle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onChange(of: state) { _, newState in
            if enableStateTransitions {
                handleStateChange(newState)
                animateForState(newState)
            }
        }
        .onAppear {
            setupInitialState()
            if enableStateTransitions {
                animateForState(state)
            }
        }
        .accessibilityLabel("View model icon")
        .accessibilityValue("State: \(state.description)")
        .accessibilityHint("Represents current view model state")
        .accessibilityAddTraits(state == .active ? .isSelected : [])
    }
    
    // Dynamic properties based on state
    private var nodeCount: Int {
        switch state {
        case .idle: return 4
        case .loading: return 6
        case .active: return 8
        case .updating: return 6
        case .error: return 3
        case .success: return 5
        }
    }
    
    private var connectionStrength: CGFloat {
        switch state {
        case .idle: return 0.3
        case .loading: return 0.8
        case .active: return 1.0
        case .updating: return 0.9
        case .error: return 0.1
        case .success: return 0.6
        }
    }
    
    // MARK: - Animation Handling
    
    private func handleStateChange(_ newState: ViewModelState) {
        #if os(iOS)
        if enableHaptics {
            switch newState {
            case .active:
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            case .success:
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            case .error:
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.error)
            default:
                break
            }
        }
        #endif
    }
    
    private func setupInitialState() {
        animationScale = 1.0
        rotationAngle = 0
        pulseOpacity = 1.0
        glowScale = 1.0
        shakeOffset = .zero
        dataFlowProgress = 1.0
    }
    
    private func animateForState(_ newState: ViewModelState) {
        // Reset all animations
        stopAllAnimations()
        
        // Apply state-specific animations
        switch newState {
        case .idle:
            withAnimation(.easeInOut(duration: 0.3)) {
                dataFlowProgress = 0.5
            }
            
        case .loading:
            // Pulsing animation
            withAnimation(affinity.animationFor(state: newState)) {
                pulseOpacity = 0.6
                animationScale = 1.1
            }
            // Data flow animation
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                dataFlowProgress = 0.2
            }
            
        case .active:
            withAnimation(.spring(response: affinity.response, dampingFraction: affinity.damping)) {
                glowScale = 1.3
                dataFlowProgress = 1.0
            }
            // Subtle glow pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowScale = 1.5
            }
            
        case .updating:
            // Rotation animation
            withAnimation(affinity.animationFor(state: newState)) {
                rotationAngle = 360
            }
            // Scale pulse
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animationScale = 1.05
            }
            
        case .error:
            // Shake animation
            withAnimation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)) {
                shakeOffset = CGSize(width: 2, height: 0)
            }
            // Reduce data flow
            withAnimation(.easeInOut(duration: 0.5)) {
                dataFlowProgress = 0.1
            }
            
        case .success:
            // Bounce animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.3)) {
                animationScale = 1.2
            }
            // Completion glow
            withAnimation(.easeInOut(duration: 0.8)) {
                glowScale = 2.0
                dataFlowProgress = 1.0
            }
            // Return to normal after celebration
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animationScale = 1.0
                    glowScale = 1.0
                }
            }
        }
    }
    
    private func stopAllAnimations() {
        // This would typically involve cancelling any ongoing animations
        // For SwiftUI, we rely on the animation system to handle transitions
        shakeOffset = .zero
    }
}

// MARK: - View Model Icon Collection
public struct ViewModelIconCollection: View {
    @State private var selectedState: ViewModelState = .idle
    @State private var selectedAffinity: CompanionAffinity = .lucis
    
    public var body: some View {
        VStack(spacing: 30) {
            Text("View Model State Icons")
                .font(.title2)
                .fontWeight(.semibold)
            
            // State demonstration
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                ForEach(ViewModelState.allCases) { state in
                    VStack {
                        ViewModelIcon(
                            state: state,
                            size: 48,
                            affinity: selectedAffinity
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedState = state
                            }
                        }
                        
                        Text(state.description.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedState == state ? Color.blue.opacity(0.1) : Color.clear)
                    )
                }
            }
            
            // Affinity selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Companion Affinity")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Picker("Affinity", selection: $selectedAffinity) {
                    ForEach(CompanionAffinity.allCases) { affinity in
                        Text(affinity.rawValue).tag(affinity)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Integration with Existing System

extension ViewModelIcon {
    /// Create an icon that morphs through states automatically for demonstration
    public static func demo(size: CGFloat = 32, affinity: CompanionAffinity = .lucis) -> some View {
        struct DemoIcon: View {
            @State private var currentStateIndex = 0
            @State private var timer: Timer?
            
            let size: CGFloat
            let affinity: CompanionAffinity
            let states = ViewModelState.allCases
            
            var body: some View {
                ViewModelIcon(
                    state: states[currentStateIndex],
                    size: size,
                    affinity: affinity
                )
                .onAppear {
                    startDemo()
                }
                .onDisappear {
                    timer?.invalidate()
                }
            }
            
            private func startDemo() {
                timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentStateIndex = (currentStateIndex + 1) % states.count
                    }
                }
            }
        }
        
        return DemoIcon(size: size, affinity: affinity)
    }
}

// MARK: - Previews

#Preview("View Model States") {
    ScrollView {
        VStack(spacing: 40) {
            // All states with different affinities
            ForEach(CompanionAffinity.allCases) { affinity in
                VStack(spacing: 15) {
                    Text("\(affinity.rawValue) Affinity")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 20) {
                        ForEach(ViewModelState.allCases) { state in
                            VStack {
                                ViewModelIcon(
                                    state: state,
                                    size: 40,
                                    affinity: affinity
                                )
                                Text(state.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
    .previewDisplayName("All States & Affinities")
}

#Preview("Interactive Collection") {
    ViewModelIconCollection()
        .previewDisplayName("Interactive View Model Icons")
}

#Preview("Demo Animation") {
    VStack(spacing: 30) {
        Text("Auto-Morphing Demo")
            .font(.title2)
            .fontWeight(.semibold)
        
        HStack(spacing: 30) {
            ForEach(CompanionAffinity.allCases) { affinity in
                VStack {
                    ViewModelIcon.demo(size: 60, affinity: affinity)
                    Text(affinity.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    .padding()
    .previewDisplayName("Auto-Morphing Demo")
}
