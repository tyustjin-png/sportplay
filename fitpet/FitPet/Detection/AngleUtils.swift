import Foundation
import CoreGraphics

/// 计算三点形成的夹角（度数，0-180）
/// - Parameters:
///   - a: 起点
///   - b: 顶点（夹角顶点）
///   - c: 终点
func calcAngle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
    let radians = atan2(Double(c.y - b.y), Double(c.x - b.x))
                - atan2(Double(a.y - b.y), Double(a.x - b.x))
    var angle = abs(radians * 180 / .pi)
    if angle > 180 { angle = 360 - angle }
    return angle
}
