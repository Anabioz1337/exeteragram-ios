import Foundation

public enum ExteraAngleMode {
    case degrees
    case radians
}

public struct ExteraEvaluationContext {
    public let angleMode: ExteraAngleMode

    public init(angleMode: ExteraAngleMode) {
        self.angleMode = angleMode
    }
}

indirect enum ExteraExpressionNode {
    case number(Double)
    case constant(Double)
    case add(ExteraExpressionNode, ExteraExpressionNode)
    case subtract(ExteraExpressionNode, ExteraExpressionNode)
    case multiply(ExteraExpressionNode, ExteraExpressionNode)
    case divide(ExteraExpressionNode, ExteraExpressionNode)
    case power(ExteraExpressionNode, ExteraExpressionNode)
    case negate(ExteraExpressionNode)
    case fractionOfHundred(ExteraExpressionNode)
    case function(String, [ExteraExpressionNode])
}

extension ExteraExpressionNode {
    var isFractionOfHundred: Bool {
        if case .fractionOfHundred = self {
            return true
        }
        return false
    }
}

private struct Token: Equatable {
    enum Kind: Equatable {
        case number(Double)
        case word(String)
        case character(Character)
    }

    let kind: Kind
}

public enum ExpressionEvaluatorError: Error {
    case emptyInput
    case syntax(message: String)
}

/// Evaluates arithmetic typed into the chat-list search field, exteraGram-style:
/// percentages taken from the value to their left (`200 + 15%`), trig respecting the
/// degree/radian setting, multiplier suffixes (`k`, `kk`, `million`) and an expression
/// language rich enough for `2*(sqrt(9) - sin(30))`.
public func evaluateExpression(_ input: String, context: ExteraEvaluationContext) throws -> Double {
    let tokens = try tokenize(input)
    guard !tokens.isEmpty else {
        throw ExpressionEvaluatorError.emptyInput
    }
    var parser = Parser(tokens: tokens, context: context)
    let root = try parser.parseAdditive()
    if !parser.isAtEnd {
        throw ExpressionEvaluatorError.syntax(message: "unbalanced expression")
    }
    return root.evaluate(context: context).value
}

private func normalizeWord(_ raw: String) -> String {
    let lowered = raw.lowercased()
    switch lowered {
    case "million":
        return "kk"
    case "m", "mm":
        return lowered
    default:
        return lowered
    }
}

private func tokenize(_ input: String) throws -> [Token] {
    var tokens: [Token] = []
    let scalars = Array(input.replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: "×", with: "*").replacingOccurrences(of: "÷", with: "/").lowercased())
    var index = 0
    while index < scalars.count {
        let scalar = scalars[index]
        if scalar == " " || scalar == "\t" || scalar == "=" {
            index += 1
            continue
        }
        if scalar.isNumber || (scalar == "." && index + 1 < scalars.count && scalars[index + 1].isNumber) {
            var digits = ""
            while index < scalars.count, scalars[index].isNumber || scalars[index] == "." {
                digits.append(scalars[index])
                index += 1
            }
            guard let value = Double(digits) else {
                throw ExpressionEvaluatorError.syntax(message: "invalid number")
            }
            // Value multipliers written straight after the literal: 2k, 1.5kk, 3m.
            if index < scalars.count, scalars[index].isLetter {
                var letters = ""
                while index < scalars.count, scalars[index].isLetter {
                    letters.append(scalars[index])
                    index += 1
                }
                if let multiplier = multiplierSuffix(normalizeWord(letters)) {
                    tokens.append(Token(kind: .number(value * multiplier)))
                } else if ["pi", "e"].contains(letters) {
                    tokens.append(Token(kind: .character("*")))
                    tokens.append(Token(kind: .word(letters)))
                } else {
                    throw ExpressionEvaluatorError.syntax(message: "unknown multiplier")
                }
            } else {
                tokens.append(Token(kind: .number(value)))
            }
            continue
        }
        if scalar.isLetter {
            var letters = ""
            while index < scalars.count, scalars[index].isLetter || scalars[index].isNumber {
                letters.append(scalars[index])
                index += 1
            }
            let normalized = normalizeWord(letters)
            if normalized == "m" || normalized == "mm" {
                guard let previousNumberIndex = tokens.indices.last, case .number(let baseValue)? = tokens[previousNumberIndex].kind else {
                    tokens.append(Token(kind: .word(normalized)))
                    continue
                }
                tokens.removeLast()
                tokens.append(Token(kind: .number(baseValue * multiplierSuffix(normalized)!)))
            } else {
                tokens.append(Token(kind: .word(normalized)))
            }
            continue
        }
        switch scalar {
        case "+", "-", "*", "/", "^", "(", ")", "%":
            tokens.append(Token(kind: .character(scalar)))
        case "'":
            break
        default:
            throw ExpressionEvaluatorError.syntax(message: "unexpected symbol")
        }
        index += 1
    }
    return tokens
}

private func multiplierSuffix(_ word: String) -> Double? {
    switch word {
    case "k":
        return 1_000.0
    case "kk", "million":
        return 1_000_000.0
    case "b", "billion":
        return 1_000_000_000.0
    case "m":
        return 1_000_000.0
    case "mm":
        return 1_000_000.0
    default:
        return nil
    }
}

private struct Parser {
    private let tokens: [Token]
    private let context: ExteraEvaluationContext
    private var position: Int = 0

    init(tokens: [Token], context: ExteraEvaluationContext) {
        self.tokens = tokens
        self.context = context
    }

    var isAtEnd: Bool {
        return self.position >= self.tokens.count
    }

    private mutating func peek() -> Token? {
        return self.position < self.tokens.count ? self.tokens[self.position] : nil
    }

    private mutating func advanceIfKind(_ kind: Token.Kind) -> Bool {
        if let token = self.peek(), token.kind == kind {
            self.position += 1
            return true
        }
        return false
    }

    mutating func parseAdditive() throws -> ExteraExpressionNode {
        var left = try self.parseMultiplicative()
        loop: while true {
            if self.advanceIfKind(.character("+")) {
                left = .add(left, try self.parseMultiplicative())
            } else if self.advanceIfKind(.character("-")) {
                left = .subtract(left, try self.parseMultiplicative())
            } else {
                break loop
            }
        }
        return left
    }

    private mutating func parseMultiplicative() throws -> ExteraExpressionNode {
        var left = try self.parseUnary()
        loop: while true {
            if self.advanceIfKind(.character("*")) {
                left = .multiply(left, try self.parseUnary())
            } else if self.advanceIfKind(.character("/")) {
                left = .divide(left, try self.parseUnary())
            } else {
                break loop
            }
        }
        return left
    }

    private mutating func parseUnary() throws -> ExteraExpressionNode {
        if self.advanceIfKind(.character("-")) {
            return .negate(try self.parseUnary())
        }
        if self.advanceIfKind(.character("+")) {
            return try self.parseUnary()
        }
        return try self.parsePower()
    }

    private mutating func parsePower() throws -> ExteraExpressionNode {
        let base = try self.parsePostfix()
        if self.advanceIfKind(.character("^")) {
            return .power(base, try self.parseUnary())
        }
        return base
    }

    private mutating func parsePostfix() throws -> ExteraExpressionNode {
        var node = try self.parsePrimary()
        while self.advanceIfKind(.character("%")) {
            node = .fractionOfHundred(node)
        }
        return node
    }

    private mutating func parsePrimary() throws -> ExteraExpressionNode {
        guard let token = self.peek() else {
            throw ExpressionEvaluatorError.syntax(message: "unexpected end")
        }
        switch token.kind {
        case let .number(value):
            self.position += 1
            return .number(value)
        case let .word(word):
            self.position += 1
            if constants[word] != nil {
                return .constant(constants[word]!)
            }
            var arguments: [ExteraExpressionNode] = []
            if self.advanceIfKind(.character("(")) {
                arguments.append(try self.parseAdditive())
                while self.advanceIfKind(.character(",")) {
                    arguments.append(try self.parseAdditive())
                }
                guard self.advanceIfKind(.character(")")) else {
                    throw ExpressionEvaluatorError.syntax(message: "missing closing bracket")
                }
            } else {
                arguments.append(try self.parseUnary())
            }
            return .function(word, arguments)
        case let .character(character):
            if character == "(" {
                self.position += 1
                let inner = try self.parseAdditive()
                guard self.advanceIfKind(.character(")")) else {
                    throw ExpressionEvaluatorError.syntax(message: "missing closing bracket")
                }
                return inner
            }
            throw ExpressionEvaluatorError.syntax(message: "unexpected symbol")
        }
    }

}

private let constants: [String: Double] = [
    "pi": Double.pi,
    "e": M_E,
    "tau": Double.pi * 2.0
]

private extension ExteraExpressionNode {
    struct EvaluatedValue {
        let value: Double
        let percentRelativeBase: Double?
    }

    func evaluate(context: ExteraEvaluationContext) -> EvaluatedValue {
        switch self {
        case let .number(value):
            return EvaluatedValue(value: value, percentRelativeBase: nil)
        case let .constant(value):
            return EvaluatedValue(value: value, percentRelativeBase: nil)
        case let .add(left, right):
            let leftValue = left.evaluate(context: context)
            let rightRaw = right.evaluate(context: context)
            if let percentage = rightRaw.percentRelativeBase {
                return EvaluatedValue(value: leftValue.value + leftValue.value * percentage, percentRelativeBase: nil)
            }
            return EvaluatedValue(value: leftValue.value + rightRaw.value, percentRelativeBase: nil)
        case let .subtract(left, right):
            let leftValue = left.evaluate(context: context)
            let rightRaw = right.evaluate(context: context)
            if let percentage = rightRaw.percentRelativeBase {
                return EvaluatedValue(value: leftValue.value - leftValue.value * percentage, percentRelativeBase: nil)
            }
            return EvaluatedValue(value: leftValue.value - rightRaw.value, percentRelativeBase: nil)
        case let .multiply(left, right):
            return EvaluatedValue(value: left.evaluate(context: context).value * right.evaluate(context: context).value, percentRelativeBase: nil)
        case let .divide(left, right):
            let divisor = right.evaluate(context: context).value
            guard divisor != 0.0 else {
                return EvaluatedValue(value: .nan, percentRelativeBase: nil)
            }
            return EvaluatedValue(value: left.evaluate(context: context).value / divisor, percentRelativeBase: nil)
        case let .power(base, exponent):
            return EvaluatedValue(value: pow(base.evaluate(context: context).value, exponent.evaluate(context: context).value), percentRelativeBase: nil)
        case let .negate(inner):
            return EvaluatedValue(value: -inner.evaluate(context: context).value, percentRelativeBase: nil)
        case let .fractionOfHundred(inner):
            let raw = inner.evaluate(context: context).value
            return EvaluatedValue(value: raw / 100.0, percentRelativeBase: raw / 100.0)
        case let .function(name, arguments):
            let argumentValues = arguments.map({ $0.evaluate(context: context).value })
            return EvaluatedValue(value: evaluateFunction(name: name, arguments: argumentValues, context: context), percentRelativeBase: nil)
        }
    }
}

private func evaluateFunction(name: String, arguments: [Double], context: ExteraEvaluationContext) -> Double {
    let usesDegrees = context.angleMode == .degrees

    func toRadians(_ angle: Double) -> Double {
        return usesDegrees ? angle * Double.pi / 180.0 : angle
    }

    func fromRadians(_ angle: Double) -> Double {
        return usesDegrees ? angle * 180.0 / Double.pi : angle
    }

    func singleArgument(_ body: (Double) -> Double) -> Double? {
        guard arguments.count == 1 else {
            return nil
        }
        return body(arguments[0])
    }

    func twoArguments(_ body: (Double, Double) -> Double) -> Double? {
        guard arguments.count == 2 else {
            return nil
        }
        return body(arguments[0], arguments[1])
    }

    switch name {
    case "sin":
        return singleArgument({ sin(toRadians($0)) }) ?? .nan
    case "cos":
        return singleArgument({ cos(toRadians($0)) }) ?? .nan
    case "tan":
        return singleArgument({ tan(toRadians($0)) }) ?? .nan
    case "asin", "arcsin":
        return singleArgument({ fromRadians(asin($0)) }) ?? .nan
    case "acos", "arccos":
        return singleArgument({ fromRadians(acos($0)) }) ?? .nan
    case "atan", "arctan":
        return singleArgument({ fromRadians(atan($0)) }) ?? .nan
    case "sqrt":
        return singleArgument({ sqrt($0) }) ?? .nan
    case "cbrt":
        return singleArgument({ cbrt($0) }) ?? .nan
    case "log":
        return twoArguments({ log($0) / log($1) }) ?? singleArgument({ log10($0) }) ?? .nan
    case "ln":
        return singleArgument({ log($0) }) ?? .nan
    case "abs":
        return singleArgument({ abs($0) }) ?? .nan
    case "exp":
        return singleArgument({ exp($0) }) ?? .nan
    case "round":
        return singleArgument({ $0.rounded(.toNearestOrAwayFromZero) }) ?? .nan
    case "floor":
        return singleArgument({ floor($0) }) ?? .nan
    case "ceil":
        return singleArgument({ ceil($0) }) ?? .nan
    default:
        return .nan
    }
}
