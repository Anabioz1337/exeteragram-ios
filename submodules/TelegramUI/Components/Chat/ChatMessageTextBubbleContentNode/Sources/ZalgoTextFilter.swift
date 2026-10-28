import Foundation
import TelegramCore

let zalgoMaximumCombiningRunLength = 10

private func isCombiningDiacriticalMark(_ scalar: Unicode.Scalar) -> Bool {
    return (0x0300...0x036F).contains(scalar.value)
}

func textHasExcessiveCombiningMarkRun(_ text: String) -> Bool {
    var runLength = 0
    for scalar in text.unicodeScalars {
        if isCombiningDiacriticalMark(scalar) {
            runLength += 1
            if runLength > zalgoMaximumCombiningRunLength {
                return true
            }
        } else {
            runLength = 0
        }
    }
    return false
}

/// Keeps at most `zalgoMaximumCombiningRunLength` consecutive combining marks,
/// dropping the remainder of each longer run.
///
/// Returns the trimmed string and a map from every UTF-16 unit index of the
/// source to its new offset (`-1` for dropped units), so dependent ranges can
/// be translated without re-parsing.
func stripExcessiveCombiningMarks(from text: String) -> (strippedText: String, utf16IndexMap: [Int]) {
    var resultScalars: [Unicode.Scalar] = []
    resultScalars.reserveCapacity(text.unicodeScalars.count)
    var indexMap: [Int] = []
    indexMap.reserveCapacity(text.utf16.count)

    var runLength = 0
    var sourceUtf16Offset = 0
    var resultUtf16Offset = 0

    for scalar in text.unicodeScalars {
        let width = UTF16.width(scalar)
        defer { sourceUtf16Offset += width }

        if isCombiningDiacriticalMark(scalar) && runLength >= zalgoMaximumCombiningRunLength {
            for _ in 0..<width {
                indexMap.append(-1)
            }
            continue
        }

        runLength = isCombiningDiacriticalMark(scalar) ? runLength + 1 : 0
        for unit in 0..<width {
            indexMap.append(resultUtf16Offset + min(unit, width - 1))
        }
        resultScalars.append(scalar)
        resultUtf16Offset += width
    }

    return (String(String.UnicodeScalarView(resultScalars)), indexMap)
}

func remapEntitiesAfterTextTrimming(_ entities: [MessageTextEntity], utf16IndexMap: [Int]) -> [MessageTextEntity] {
    var remapped: [MessageTextEntity] = []
    remapped.reserveCapacity(entities.count)
    for entity in entities {
        let originalLowerBound = max(0, Int(entity.range.lowerBound))
        let originalUpperBound = min(utf16IndexMap.count, Int(entity.range.upperBound))
        guard originalUpperBound > originalLowerBound else {
            continue
        }

        var firstKeptUnit: Int?
        var lastKeptUnit: Int?
        for sourceIndex in originalLowerBound..<originalUpperBound where utf16IndexMap[sourceIndex] >= 0 {
            if firstKeptUnit == nil {
                firstKeptUnit = utf16IndexMap[sourceIndex]
            }
            lastKeptUnit = utf16IndexMap[sourceIndex]
        }

        guard let lowerBound = firstKeptUnit, let upperBoundEnd = lastKeptUnit else {
            continue
        }

        remapped.append(MessageTextEntity(range: lowerBound..<(upperBoundEnd + 1), type: entity.type))
    }
    return remapped
}
