import XCTest
@testable import FitPet

final class PetGrowthServiceTests: XCTestCase {
    func test_realmCalculation() {
        XCTAssertEqual(PetGrowthService.realm(for: 1),  1)
        XCTAssertEqual(PetGrowthService.realm(for: 27), 1)
        XCTAssertEqual(PetGrowthService.realm(for: 28), 2)
        XCTAssertEqual(PetGrowthService.realm(for: 54), 2)
        XCTAssertEqual(PetGrowthService.realm(for: 55), 3)
    }

    func test_levelInRealm() {
        XCTAssertEqual(PetGrowthService.levelInRealm(for: 1),  1)
        XCTAssertEqual(PetGrowthService.levelInRealm(for: 27), 27)
        XCTAssertEqual(PetGrowthService.levelInRealm(for: 28), 1)
        XCTAssertEqual(PetGrowthService.levelInRealm(for: 29), 2)
    }

    func test_levelIncreasesOnHighCompletion() {
        XCTAssertEqual(PetGrowthService.newLevel(currentLevel: 5, completionRate: 0.9, consecutiveHighDays: 1), 6)
    }

    func test_levelDecreasesOnLowCompletion() {
        XCTAssertEqual(PetGrowthService.newLevel(currentLevel: 5, completionRate: 0.3, consecutiveHighDays: 0), 4)
    }

    func test_levelDoesNotDropBelowRealmStart() {
        XCTAssertEqual(PetGrowthService.newLevel(currentLevel: 28, completionRate: 0.1, consecutiveHighDays: 0), 28)
    }

    func test_levelCapAtRealmEndNormallyNoPromotion() {
        XCTAssertEqual(PetGrowthService.newLevel(currentLevel: 27, completionRate: 0.9, consecutiveHighDays: 3), 27)
    }

    func test_realmPromotionAfter7HighDays() {
        XCTAssertEqual(PetGrowthService.newLevel(currentLevel: 27, completionRate: 0.9, consecutiveHighDays: 7), 28)
    }

    func test_dragonForms() {
        XCTAssertEqual(PetGrowthService.dragonForm(for: 1),  .egg)
        XCTAssertEqual(PetGrowthService.dragonForm(for: 28), .hatchling)
        XCTAssertEqual(PetGrowthService.dragonForm(for: 55), .young)
        XCTAssertEqual(PetGrowthService.dragonForm(for: 82), .divine)
    }
}
