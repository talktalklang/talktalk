[
"var"
"print"
"if"
"else"
"while"
"func"
"return"
"class"
] @keyword
(comment) @comment
(call) @function.call
(function_declaration name: (identifier)) @function.name
(string_literal) @string
(number_literal) @number
(class_declaration name: (identifier)) @type
