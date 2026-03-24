import XCTest
import simd
@testable import Chromafield

final class ColorPaletteTests: XCTestCase {

    func testAllPalettesHaveFourStops() {
        for (i, palette) in palettes.enumerated() {
            XCTAssertEqual(palette.count, 4, "Palette \(i) must have exactly 4 color stops")
        }
    }

    func testPaletteCountMatchesNames() {
        XCTAssertEqual(palettes.count, paletteNames.count,
                       "Palette count must match name count")
        XCTAssertEqual(palettes.count, 8, "Must have exactly 8 palettes")
    }

    func testAllColorsInValidRange() {
        for (i, palette) in palettes.enumerated() {
            for (j, color) in palette.enumerated() {
                XCTAssertTrue(color.x >= 0 && color.x <= 1,
                              "Palette \(i) stop \(j): R out of range (\(color.x))")
                XCTAssertTrue(color.y >= 0 && color.y <= 1,
                              "Palette \(i) stop \(j): G out of range (\(color.y))")
                XCTAssertTrue(color.z >= 0 && color.z <= 1,
                              "Palette \(i) stop \(j): B out of range (\(color.z))")
                XCTAssertTrue(color.w >= 0 && color.w <= 1,
                              "Palette \(i) stop \(j): A out of range (\(color.w))")
            }
        }
    }

    func testPaletteNamesAreUnique() {
        let uniqueNames = Set(paletteNames)
        XCTAssertEqual(uniqueNames.count, paletteNames.count, "Palette names must be unique")
    }
}
