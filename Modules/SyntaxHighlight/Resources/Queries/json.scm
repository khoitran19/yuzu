; Source: https://github.com/tree-sitter/tree-sitter-json/blob/v0.24.8/queries/highlights.scm (MIT)
(pair
  key: (_) @string.special.key)

(string) @string

(number) @number

[
  (null)
  (true)
  (false)
] @constant.builtin

(escape_sequence) @escape

(comment) @comment
