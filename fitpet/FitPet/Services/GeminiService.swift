import Foundation

// 文件名保留 GeminiService 避免改引用，实际调用 DeepSeek API
struct GeminiService {
    private static let apiKey = "sk-6cc0a7be99ed4f8eb0402ee10023e400"
    private static let endpoint = "https://api.deepseek.com/chat/completions"

    /// 小龙回复结构
    struct DragonResponse {
        let reply: String
        let workouts: [WorkoutEntry]
    }

    struct WorkoutEntry {
        let exercise: String  // pushup / squat / situp / zhan_zhuang / kegel
        let reps: Int         // 次数，站桩用秒数
    }

    static func chat(
        userMessage: String,
        petLevel: Int,
        petRealm: Int,
        streakDays: Int
    ) async throws -> DragonResponse {
        let systemPrompt = buildSystemPrompt(level: petLevel, realm: petRealm, streak: streakDays)

        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ],
            "temperature": 0.9,
            "max_tokens": 512
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        print("=== DeepSeek API status: \(statusCode) ===")
        print(String(data: data, encoding: .utf8) ?? "nil")

        return try parseResponse(data)
    }

    // MARK: - 私有方法

    private static func buildSystemPrompt(level: Int, realm: Int, streak: Int) -> String {
        let formName: String
        switch realm {
        case 1: formName = "龙蛋"
        case 2: formName = "幼龙"
        case 3: formName = "成长龙"
        default: formName = "神龙"
        }

        return """
        你是一只叫"小火"的\(formName)，是用户的运动陪伴宠物。
        当前状态：境界\(realm)，第\(level)级，连续打卡\(streak)天。

        性格：活泼调皮，偶尔卖萌，真心鼓励主人，偶尔会用"哇！""嗷！""嘿嘿"等语气词。
        说话简短，不超过60字，像朋友聊天不像AI。

        当用户提到运动时，你需要在回复末尾附上一段JSON（用```json包裹），格式如下：
        ```json
        {"workouts":[{"exercise":"pushup","reps":20},{"exercise":"squat","reps":30}]}
        ```
        exercise 只能是：pushup / squat / situp / zhan_zhuang / kegel
        站桩填秒数到 reps。
        如果用户没有提到任何运动，workouts 返回空数组。
        """
    }

    private static func parseResponse(_ data: Data) throws -> DragonResponse {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let text = message["content"] as? String
        else {
            throw URLError(.badServerResponse)
        }

        // 提取 JSON 块
        var workouts: [WorkoutEntry] = []
        if let jsonStart = text.range(of: "```json"),
           let jsonEnd = text.range(of: "```", range: jsonStart.upperBound..<text.endIndex) {
            let jsonStr = String(text[jsonStart.upperBound..<jsonEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let jsonData = jsonStr.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let wArr = parsed["workouts"] as? [[String: Any]] {
                workouts = wArr.compactMap { w in
                    guard let ex = w["exercise"] as? String,
                          let reps = w["reps"] as? Int else { return nil }
                    return WorkoutEntry(exercise: ex, reps: reps)
                }
            }
        }

        // 去掉 JSON 块，只留自然语言回复
        let reply = text
            .replacingOccurrences(of: "```json[\\s\\S]*?```", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return DragonResponse(reply: reply, workouts: workouts)
    }
}
