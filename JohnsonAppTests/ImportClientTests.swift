//
//  ImportClientTests.swift
//  JohnsonApp
//

import XCTest
@testable import JohnsonApp

final class ImportClientTests: XCTestCase {
    private var client: ImportClient!

    override func setUp() {
        super.setUp()
        client = .liveValue
    }

    override func tearDown() {
        client = nil
        super.tearDown()
    }

    // MARK: - Valid lines

    func testSimpleLine() {
        let result = client.parse("apple - яблуко")

        XCTAssertEqual(result.validTerms.count, 1)
        XCTAssertEqual(result.validTerms[0].termText, "apple")
        XCTAssertEqual(result.validTerms[0].translation, "яблуко")
        XCTAssertNil(result.validTerms[0].hint)
        XCTAssertTrue(result.invalidLines.isEmpty)
    }

    func testLineWithHint() {
        let result = client.parse("bank - банк (не берег)")

        XCTAssertEqual(result.validTerms.count, 1)
        XCTAssertEqual(result.validTerms[0].termText, "bank")
        XCTAssertEqual(result.validTerms[0].translation, "банк")
        XCTAssertEqual(result.validTerms[0].hint, "не берег")
    }

    func testMultiwordTerm() {
        let result = client.parse("take off - злітати")

        XCTAssertEqual(result.validTerms.count, 1)
        XCTAssertEqual(result.validTerms[0].termText, "take off")
        XCTAssertEqual(result.validTerms[0].translation, "злітати")
    }

    func testMultiwordTermWithHint() {
        let result = client.parse("take off - злітати (про літак)")

        XCTAssertEqual(result.validTerms.count, 1)
        XCTAssertEqual(result.validTerms[0].termText, "take off")
        XCTAssertEqual(result.validTerms[0].translation, "злітати")
        XCTAssertEqual(result.validTerms[0].hint, "про літак")
    }

    // MARK: - Dash in translation

    func testDashInTranslation() {
        // First " - " is the separator, the rest belongs to translation
        let result = client.parse("a - b - c")

        XCTAssertEqual(result.validTerms.count, 1)
        XCTAssertEqual(result.validTerms[0].termText, "a")
        XCTAssertEqual(result.validTerms[0].translation, "b - c")
    }

    // MARK: - Whitespace handling

    func testLeadingTrailingSpacesAreTrimmed() {
        let result = client.parse("  apple  -  яблуко  ")

        XCTAssertEqual(result.validTerms.count, 1)
        XCTAssertEqual(result.validTerms[0].termText, "apple")
        XCTAssertEqual(result.validTerms[0].translation, "яблуко")
    }

    func testEmptyLinesAreSkipped() {
        let text = """
        apple - яблуко

        banana - банан
        """
        let result = client.parse(text)

        XCTAssertEqual(result.validTerms.count, 2)
        XCTAssertTrue(result.invalidLines.isEmpty)
    }

    func testWhitespaceOnlyLinesAreSkipped() {
        let text = "apple - яблуко\n   \nbanana - банан"
        let result = client.parse(text)

        XCTAssertEqual(result.validTerms.count, 2)
        XCTAssertTrue(result.invalidLines.isEmpty)
    }

    // MARK: - Invalid lines

    func testLineWithoutSeparatorIsInvalid() {
        let result = client.parse("apple яблуко")

        XCTAssertTrue(result.validTerms.isEmpty)
        XCTAssertEqual(result.invalidLines.count, 1)
        XCTAssertEqual(result.invalidLines[0].lineNumber, 1)
        XCTAssertEqual(result.invalidLines[0].content, "apple яблуко")
    }

    func testLineWithOnlyDashIsInvalid() {
        let result = client.parse("-")

        XCTAssertTrue(result.validTerms.isEmpty)
        XCTAssertEqual(result.invalidLines.count, 1)
    }

    // MARK: - Mixed input

    func testMixedValidAndInvalidLines() {
        let text = """
        apple - яблуко
        invalid line
        bank - банк (не берег)
        no separator here
        take off - злітати
        """
        let result = client.parse(text)

        XCTAssertEqual(result.validTerms.count, 3)
        XCTAssertEqual(result.invalidLines.count, 2)
        XCTAssertEqual(result.invalidLines[0].lineNumber, 2)
        XCTAssertEqual(result.invalidLines[1].lineNumber, 4)
    }

    func testLineNumbersAreCorrectWithEmptyLines() {
        let text = """
        apple - яблуко

        invalid line
        """
        let result = client.parse(text)

        XCTAssertEqual(result.validTerms.count, 1)
        XCTAssertEqual(result.invalidLines.count, 1)
        // Empty line 2 is skipped, invalid is on line 3
        XCTAssertEqual(result.invalidLines[0].lineNumber, 3)
    }

    // MARK: - Edge cases

    func testEmptyTextReturnsEmptyResult() {
        let result = client.parse("")

        XCTAssertTrue(result.validTerms.isEmpty)
        XCTAssertTrue(result.invalidLines.isEmpty)
    }

    func testHintWithSpacesInsideParens() {
        let result = client.parse("run - бігти (про людину або тварину)")

        XCTAssertEqual(result.validTerms[0].hint, "про людину або тварину")
    }

    func testIncompleteHintParensArePartOfTranslation() {
        // Opening paren without closing → not a hint, whole thing is translation
        let result = client.parse("term - translation (no closing paren")

        XCTAssertEqual(result.validTerms.count, 1)
        XCTAssertEqual(result.validTerms[0].translation, "translation (no closing paren")
        XCTAssertNil(result.validTerms[0].hint)
    }

    func testEmptyHintParensAreIgnored() {
        // "()" at end — empty hint, treated as translation
        let result = client.parse("term - translation ()")

        XCTAssertEqual(result.validTerms.count, 1)
        XCTAssertEqual(result.validTerms[0].translation, "translation ()")
        XCTAssertNil(result.validTerms[0].hint)
    }
}
