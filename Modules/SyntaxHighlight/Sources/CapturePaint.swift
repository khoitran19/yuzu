import DiffEngine

enum CapturePaint: Equatable {
    /// The capture does not change the color.
    case ignore
    /// The capture resets the text to the default color.
    case plain
    case token(TokenKind)

    init(captureName name: String) {
        switch name {
        case "string.special.key", "variable.member": self = .token(.property)
        case "variable.builtin": self = .token(.variable)
        case "type.qualifier": self = .token(.keyword)
        case "string.escape", "text.title", "text.reference": self = .token(.constant)
        case "text.literal", "text.uri": self = .token(.string)
        default: self = Self(captureGroup: name.prefix { $0 != "." })
        }
    }

    private init(captureGroup: Substring) {
        switch captureGroup {
        case "keyword", "conditional", "repeat", "include", "exception", "storageclass",
             "import", "media", "charset", "keyframes", "supports", "namespace":
            self = .token(.keyword)
        case "string", "character": self = .token(.string)
        case "number", "float": self = .token(.number)
        case "boolean", "constant", "escape": self = .token(.constant)
        case "comment": self = .token(.comment)
        case "function", "method": self = .token(.function)
        case "type", "constructor": self = .token(.type)
        case "property", "field": self = .token(.property)
        case "tag": self = .token(.tag)
        case "attribute": self = .token(.attribute)
        case "operator": self = .token(.operator)
        case "punctuation": self = .token(.punctuation)
        case "variable", "parameter", "embedded", "none": self = .plain
        default: self = .ignore
        }
    }
}
