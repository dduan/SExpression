public indirect enum SExpression {
    public struct Token {
        var index: Int
        var content: String
    }

    public enum Atom {
        case string(Token)
        case symbol(Token)
    }
    case atom(Atom)
    case list([SExpression])
}

extension SExpression: CustomStringConvertible {
    public var description: String {
        switch self {
        case .list(let subExpressions):
            return "(\(subExpressions.map { String(describing: $0) } .joined(separator: " ")))"
        case .atom(.string(let token)):
            return token.content
        case .atom(.symbol(let token)):
            return "[\(token.content)]"
        }
    }
}

let kWhitespaceCharacters = Set(" \n\r\r\n")
let kNewLineCharacters = Set("\r\r\n")

extension SExpression {
    enum ParsingError: Error {
        case invalid
        case unexpectedEnding(Token)
    }

    public struct ParsingPosition {
        var line: UInt
        var column: UInt
    }

    private static func update(_ position: inout ParsingPosition, forToken token: Character) {
        if kNewLineCharacters.contains(token) {
            position.line += 1
            position.column = 0
        } else {
            position.column += 1
        }
    }

    enum LexerState {
        enum StringState {
            case body
            case escape
        }

        case normal
        case symbol
        case string(StringState)
    }

    static func lex(source: String) -> [Token] {
        var bufferStart = 0
        var buffer = [Character]()
        var tokens = [Token]()
        var state: LexerState = .normal
    
        for (index, c) in source.enumerated() {
            switch state {
            case .normal:
                if kWhitespaceCharacters.contains(c) {
                    continue
                }

                switch c {
                case _ where kWhitespaceCharacters.contains(c):
                    continue
                case "(", ")":
                    tokens.append(Token(index: index, content: String(c)))
                case "\"":
                    bufferStart = index
                    buffer = [c]
                    state = .string(.body)
                default:
                    bufferStart = index
                    buffer = [c]
                    state = .symbol
                }
            case .symbol:
                switch c {
                case ")":
                    tokens.append(Token(index: bufferStart, content: String(buffer)))
                    tokens.append(Token(index: index, content: String(")")))
                    state = .normal
                case _ where kWhitespaceCharacters.contains(c):
                    tokens.append(Token(index: bufferStart, content: String(buffer)))
                    state = .normal
                default:
                    buffer.append(c)
                }
            case .string(.body):
                switch c {
                case "\"":
                    tokens.append(Token(index: bufferStart, content: String(buffer + [c])))
                    state = .normal
                case "\\":
                    state = .string(.escape)
                default:
                    buffer.append(c)
                }
            case .string(.escape):
                buffer.append(c)
                state = .string(.body)
            }
        }
        return tokens
    }

    public static func parse(_ tokens: [Token]) throws -> SExpression {
        func parse(_ tokens: ArraySlice<Token>) throws -> (SExpression?, ArraySlice<Token>) {
            switch tokens.first?.content {
            case .none:
                return (nil, [])
            case .some("("):
                var subExpressions = [SExpression]()
                if tokens.count == 1 {
                    throw ParsingError.unexpectedEnding(tokens[0])
                }

                var nextSlice = tokens.dropFirst()
                while let nextToken = nextSlice.first, nextToken.content != ")" {
                    let (expression, newSlice) = try parse(nextSlice)
                    guard let newExpression = expression else {
                        throw ParsingError.unexpectedEnding(nextToken)
                    }

                    subExpressions.append(newExpression)
                    nextSlice = newSlice
                }

                if nextSlice.isEmpty {
                    throw ParsingError.unexpectedEnding(tokens.last!)
                }

                return (.list(subExpressions), nextSlice.dropFirst())

            case .some(let content) where content.first == "\"":
                return (.atom(.string(tokens.first!)), tokens.dropFirst())
            default:
                return (.atom(.symbol(tokens.first!)), tokens.dropFirst())
            }
        }

        guard let result = try parse(tokens[...]).0 else {
            throw ParsingError.invalid
        }

        return result
    }

    public static func parse(source: String) throws -> SExpression {
        let tokens = lex(source: source)
        return try parse(tokens)
    }
}
