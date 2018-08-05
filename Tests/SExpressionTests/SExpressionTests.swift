import XCTest
import SExpression

final class SExpressionTests: XCTestCase {
    func testEndToEndParsing() {
        let source = "( (a1 a2 (a3 a4 \"xyz \\\"x\")))"
        XCTAssertEqual(
            try SExpression.parse(source: source).description,
            "(([a1] [a2] ([a3] [a4] \"xyz \"x\")))"
        )
    }


    static var allTests = [
        ("testExample", testEndToEndParsing),
    ]
}
