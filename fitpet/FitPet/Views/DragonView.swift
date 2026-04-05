import SwiftUI

struct DragonView: View {
    let form: DragonForm
    let mood: PetMood
    let isWorkingOut: Bool

    @State private var breathScale: CGFloat = 1.0
    @State private var jumpOffset: CGFloat  = 0

    var body: some View {
        ZStack {
            dragonShape
                .scaleEffect(breathScale)
                .offset(y: jumpOffset)
        }
        .frame(width: 160, height: 160)
        .onAppear { startAnimations() }
        .onChange(of: isWorkingOut) { _, working in
            if working { startJumpAnimation() } else { startBreathAnimation() }
        }
    }

    @ViewBuilder
    private var dragonShape: some View {
        switch form {
        case .egg:       EggShape(mood: mood)
        case .hatchling: HatchlingShape(mood: mood)
        case .young:     YoungDragonShape(mood: mood)
        case .divine:    DivineDragonShape(mood: mood)
        }
    }

    private func startAnimations() {
        if isWorkingOut { startJumpAnimation() } else { startBreathAnimation() }
    }

    private func startBreathAnimation() {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            breathScale = 1.05
        }
        jumpOffset = 0
    }

    private func startJumpAnimation() {
        breathScale = 1.0
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            jumpOffset = -12
        }
    }
}

struct EggShape: View {
    let mood: PetMood
    @State private var shimmer: CGFloat = -1.0

    var body: some View {
        ZStack {
            // 底层渐变蛋壳
            Ellipse()
                .fill(baseGradient)
                .frame(width: 100, height: 120)

            // 光泽层
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.clear],
                        startPoint: .init(x: 0.2, y: 0.0),
                        endPoint: .init(x: 0.6, y: 0.5)
                    )
                )
                .frame(width: 100, height: 120)

            // 鳞片纹路
            EggScalePattern(colors: scaleColors)
                .frame(width: 100, height: 120)
                .clipShape(Ellipse())
                .opacity(0.45)

            // 流光扫过
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.6), Color.clear],
                        startPoint: .init(x: shimmer, y: 0),
                        endPoint: .init(x: shimmer + 0.4, y: 1)
                    )
                )
                .frame(width: 100, height: 120)
                .blendMode(.screen)

            // 眼睛
            HStack(spacing: 14) {
                Circle().fill(Color.white).frame(width: 10, height: 10)
                    .overlay(Circle().fill(eyeColor).frame(width: 5, height: 5))
                Circle().fill(Color.white).frame(width: 10, height: 10)
                    .overlay(Circle().fill(eyeColor).frame(width: 5, height: 5))
            }
            .offset(y: 12)
        }
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shimmer = 1.2
            }
        }
    }

    private var baseGradient: LinearGradient {
        switch mood {
        case .happy:
            return LinearGradient(
                colors: [Color(red:0.2,green:0.9,blue:0.6), Color(red:0.0,green:0.6,blue:0.8), Color(red:0.4,green:0.2,blue:0.9)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neutral:
            return LinearGradient(
                colors: [Color(red:0.4,green:0.5,blue:1.0), Color(red:0.2,green:0.3,blue:0.8), Color(red:0.6,green:0.3,blue:0.9)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sad:
            return LinearGradient(
                colors: [Color(red:0.5,green:0.5,blue:0.6), Color(red:0.3,green:0.3,blue:0.4)],
                startPoint: .top, endPoint: .bottom)
        }
    }

    private var scaleColors: [Color] {
        switch mood {
        case .happy:   return [.cyan, .green, .teal]
        case .neutral: return [.blue, .purple, .indigo]
        case .sad:     return [.gray, .gray.opacity(0.5)]
        }
    }

    private var eyeColor: Color {
        switch mood {
        case .happy:   return .green
        case .neutral: return .blue
        case .sad:     return .gray
        }
    }
}

/// 蛋壳鳞片纹路
struct EggScalePattern: View {
    let colors: [Color]

    var body: some View {
        Canvas { ctx, size in
            let rows = 7
            let cols = 5
            let w = size.width / CGFloat(cols)
            let h = size.height / CGFloat(rows)

            for row in 0..<rows {
                for col in 0..<cols {
                    let offsetX = row % 2 == 0 ? 0.0 : w / 2
                    let x = CGFloat(col) * w + offsetX
                    let y = CGFloat(row) * h
                    let color = colors[(row + col) % colors.count]

                    var path = Path()
                    path.move(to: CGPoint(x: x + w / 2, y: y))
                    path.addQuadCurve(
                        to: CGPoint(x: x + w, y: y + h * 0.6),
                        control: CGPoint(x: x + w * 1.1, y: y + h * 0.2))
                    path.addQuadCurve(
                        to: CGPoint(x: x + w / 2, y: y + h * 0.85),
                        control: CGPoint(x: x + w * 0.9, y: y + h))
                    path.addQuadCurve(
                        to: CGPoint(x: x, y: y + h * 0.6),
                        control: CGPoint(x: x - w * 0.1, y: y + h))
                    path.addQuadCurve(
                        to: CGPoint(x: x + w / 2, y: y),
                        control: CGPoint(x: x - w * 0.1, y: y + h * 0.2))

                    ctx.stroke(path, with: .color(color), lineWidth: 1.2)
                }
            }
        }
    }
}

struct HatchlingShape: View {
    let mood: PetMood

    var body: some View {
        ZStack {
            Ellipse()
                .fill(bodyGradient)
                .frame(width: 80, height: 90)
            Circle()
                .fill(bodyGradient)
                .frame(width: 60, height: 60)
                .offset(y: -55)
            HStack(spacing: 10) {
                Circle().fill(Color.white).frame(width: 14, height: 14)
                    .overlay(Circle().fill(Color.black).frame(width: 7, height: 7))
                Circle().fill(Color.white).frame(width: 14, height: 14)
                    .overlay(Circle().fill(Color.black).frame(width: 7, height: 7))
            }
            .offset(y: -58)
            HStack(spacing: 30) {
                Triangle().fill(Color.orange).frame(width: 10, height: 14).rotationEffect(.degrees(-20))
                Triangle().fill(Color.orange).frame(width: 10, height: 14).rotationEffect(.degrees(20))
            }
            .offset(y: -80)
        }
    }

    private var bodyGradient: LinearGradient {
        switch mood {
        case .happy:   return LinearGradient(colors: [Color(red:0.2,green:0.8,blue:0.4), Color(red:0.1,green:0.6,blue:0.3)], startPoint: .top, endPoint: .bottom)
        case .neutral: return LinearGradient(colors: [Color(red:0.3,green:0.5,blue:0.9), Color(red:0.2,green:0.3,blue:0.7)], startPoint: .top, endPoint: .bottom)
        case .sad:     return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .top, endPoint: .bottom)
        }
    }
}

struct YoungDragonShape: View {
    let mood: PetMood

    var body: some View {
        ZStack {
            WingShape()
                .fill(wingColor.opacity(0.7))
                .frame(width: 60, height: 50)
                .offset(x: -55, y: -10)
                .rotationEffect(.degrees(-20), anchor: .trailing)
            WingShape()
                .fill(wingColor.opacity(0.7))
                .frame(width: 60, height: 50)
                .offset(x: 55, y: -10)
                .scaleEffect(x: -1)
                .rotationEffect(.degrees(20), anchor: .leading)
            Ellipse()
                .fill(bodyGradient)
                .frame(width: 70, height: 85)
            Circle()
                .fill(bodyGradient)
                .frame(width: 55, height: 55)
                .offset(y: -55)
            HStack(spacing: 10) {
                dragonEye
                dragonEye
            }
            .offset(y: -58)
        }
    }

    private var dragonEye: some View {
        Circle().fill(Color.white).frame(width: 14, height: 14)
            .overlay(Circle().fill(mood == .happy ? Color.green : Color.blue).frame(width: 8, height: 8))
    }

    private var bodyGradient: LinearGradient {
        LinearGradient(colors: [Color(red:0.1,green:0.7,blue:0.5), Color(red:0.0,green:0.5,blue:0.3)], startPoint: .top, endPoint: .bottom)
    }

    private var wingColor: Color { mood == .sad ? .gray : Color(red:0.2, green:0.8, blue:0.6) }
}

struct DivineDragonShape: View {
    let mood: PetMood
    @State private var glowRadius: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.3))
                .frame(width: 130, height: 130)
                .blur(radius: glowRadius)
            WingShape()
                .fill(Color.yellow.opacity(0.8))
                .frame(width: 70, height: 55)
                .offset(x: -60, y: -10)
                .rotationEffect(.degrees(-25), anchor: .trailing)
            WingShape()
                .fill(Color.yellow.opacity(0.8))
                .frame(width: 70, height: 55)
                .offset(x: 60, y: -10)
                .scaleEffect(x: -1)
                .rotationEffect(.degrees(25), anchor: .leading)
            Ellipse()
                .fill(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom))
                .frame(width: 75, height: 90)
            Circle()
                .fill(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom))
                .frame(width: 58, height: 58)
                .offset(y: -58)
            HStack(spacing: 10) {
                Circle().fill(Color.white).frame(width: 14, height: 14)
                    .overlay(Circle().fill(Color(red:1,green:0.8,blue:0)).frame(width: 8, height: 8))
                Circle().fill(Color.white).frame(width: 14, height: 14)
                    .overlay(Circle().fill(Color(red:1,green:0.8,blue:0)).frame(width: 8, height: 8))
            }
            .offset(y: -60)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowRadius = 20
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

struct WingShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY),
                           control: CGPoint(x: rect.midX, y: rect.minY - 10))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                           control: CGPoint(x: rect.minX, y: rect.maxY))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DragonView(form: .egg,       mood: .happy,   isWorkingOut: false)
        DragonView(form: .hatchling, mood: .neutral, isWorkingOut: false)
        DragonView(form: .young,     mood: .sad,     isWorkingOut: true)
        DragonView(form: .divine,    mood: .happy,   isWorkingOut: false)
    }
    .padding()
    .background(Color.black)
}
