import XCTest

import SExpressionTests

var tests = [XCTestCaseEntry]()
tests += SExpressionTests.allTests()
XCTMain(tests)