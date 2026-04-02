import SwiftUI

struct DragonView: View {
    let form: PetGrowthService.DragonForm
    let mood: PetGrowthService.PetMood
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
    let mood: PetGrowthService.PetMood

    var body: some View {
        ZStack {
            Ellipse()
                .fill(moodGradient)
                .frame(width: 100, height: 120)
            Path { p in
                p.move(to: CGPoint(x: 50, y: 20))
                p.addLine(to: CGPoint(x: 45, y: 50))
                p.addLine(to: CGPoint(x: 55, y: 70))
            }
            .stroke(Color.white.opacity(0.6), lineWidth: 2)
            .frame(width: 100, height: 120)
            HStack(spacing: 14) {
                Circle().fill(Color.white).frame(width: 12, height: 12)
                Circle().fill(Color.white).frame(width: 12, height: 12)
            }
            .offset(y: 10)
        }
    }

    private var moodGradient: LinearGradient {
        switch mood {
        case .happy:   return LinearGradient(colors: [.green, .teal],  startPoint: .top, endPoint: .bottom)
        case .neutral: return LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom)
        case .sad:     return LinearGradient(colors: [.gray, .gray.opacity(0.6)], startPoint: .top, endPoint: .bottom)
        }
    }
}

struct HatchlingShape: View {
    let mood: PetGrowthService.PetMood

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
    let mood: PetGrowthService.PetMood

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
    let mood: PetGrowthService.PetMood
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
