enum UnifiedPatch {
    private enum Operation {
        case context(old: Int, new: Int)
        case deletion(old: Int)
        case addition(new: Int)

        var isChange: Bool {
            if case .context = self { return false }
            return true
        }
    }

    static func make(old: [Substring], new: [Substring], context: Int) -> String {
        let operations = operations(old: old, new: new)
        let changeIndices = operations.indices.filter { operations[$0].isChange }
        guard let firstChange = changeIndices.first else { return "" }

        var groups: [ClosedRange<Int>] = []
        var groupStart = firstChange
        var groupEnd = firstChange
        for index in changeIndices.dropFirst() {
            if index - groupEnd > context * 2 {
                groups.append(groupStart...groupEnd)
                groupStart = index
            }
            groupEnd = index
        }
        groups.append(groupStart...groupEnd)

        var output = ""
        for group in groups {
            let slice = operations[max(0, group.lowerBound - context)...min(operations.count - 1, group.upperBound + context)]
            var oldCount = 0
            var newCount = 0
            var oldStart: Int?
            var newStart: Int?
            var body = ""
            for operation in slice {
                switch operation {
                case let .context(oldIndex, newIndex):
                    oldStart = oldStart ?? oldIndex + 1
                    newStart = newStart ?? newIndex + 1
                    oldCount += 1
                    newCount += 1
                    body += " \(old[oldIndex])\n"
                case let .deletion(oldIndex):
                    oldStart = oldStart ?? oldIndex + 1
                    oldCount += 1
                    body += "-\(old[oldIndex])\n"
                case let .addition(newIndex):
                    newStart = newStart ?? newIndex + 1
                    newCount += 1
                    body += "+\(new[newIndex])\n"
                }
            }
            output += "@@ -\(oldCount == 0 ? 0 : oldStart ?? 0),\(oldCount) +\(newCount == 0 ? 0 : newStart ?? 0),\(newCount) @@\n"
            output += body
        }
        return output
    }

    private static func operations(old: [Substring], new: [Substring]) -> [Operation] {
        let difference = new.difference(from: old)
        var removed = Set<Int>()
        var inserted = Set<Int>()
        for change in difference {
            switch change {
            case let .remove(offset, _, _): removed.insert(offset)
            case let .insert(offset, _, _): inserted.insert(offset)
            }
        }
        var result: [Operation] = []
        result.reserveCapacity(max(old.count, new.count))
        var oldIndex = 0
        var newIndex = 0
        while oldIndex < old.count || newIndex < new.count {
            if oldIndex < old.count, removed.contains(oldIndex) {
                result.append(.deletion(old: oldIndex))
                oldIndex += 1
            } else if newIndex < new.count, inserted.contains(newIndex) {
                result.append(.addition(new: newIndex))
                newIndex += 1
            } else {
                result.append(.context(old: oldIndex, new: newIndex))
                oldIndex += 1
                newIndex += 1
            }
        }
        return result
    }
}
