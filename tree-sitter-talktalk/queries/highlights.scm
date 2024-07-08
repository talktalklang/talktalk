[
"var"
"if"
"else"
"while"
"func"
"return"
"class"
"init"
] @keyword
(comment) @comment
(call) @function.call
(function name: (identifier)) @function.name
(string) @string
(number) @number
(classDecl name: (identifier)) @type
(parameters) @function.parameters
(init (block)) @constructor
