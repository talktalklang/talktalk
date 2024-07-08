module.exports = grammar({
  name: 'talktalk',

  extras: $ => [
    /[\s\t]+/,
    $.comment,
  ],

  rules: {
    source_file: $ => repeat($.declaration),

    comment: _ => token(choice(
      // Single-line comments (including documentation comments)
      seq(/\/{2,3}[^/].*/),
      // Multiple-line comments (including documentation comments).
      seq(
        /\/\*{1,}[^*]*\*+([^/*][^*]*\*+)*\//,
      ),
    )),

    declaration: $ => choice(
      $.classDecl,
      $.funcDecl,
      $.varDecl,
      $.statement
    ),

    classDecl: $ => seq(
      "class",
      field('name', $.identifier),
      optional(
        seq(":", $.identifier)
      ),
      "{",
      repeat(
        choice(
          $.init,
          $.function
        )
      ),
      "}"
    ),

    funcDecl: $ => seq(
      "func",
      $.function
    ),

    varDecl: $ => seq(
      "var",
      $.identifier,
      optional(
        seq("=", $.expr)
      ),
      choice("\n", ";")
    ),

    statement: $ => seq(
      choice(
        $.exprStmt,
        $.ifStmt,
        $.returnStmt,
        $.whileStmt,
        $.block
      )
    ),

    exprStmt: $ => $.expr,

    ifStmt: $ => seq(
      "if",
      $.expr,
      $.block,
      optional(seq(
        "else",
        $.statement
      ))
    ),

    returnStmt: $ => seq(
        "return",
        optional(
          $.expr
        ),
        optional(";")
      ),

    whileStmt: $ => seq(
      "while",
      $.expr,
      $.block
    ),

    block: $ => seq(
      "{",
      repeat(
        $.declaration
      ),
      "}"
    ),

    expr: $ => $.assignment,

    assignment: $ => choice(
      seq(
        optional(
          seq(
            $.call,
            "."
          )
        ),
        $.identifier,
        "=",
        $.assignment
      ),
      $.logic_or
    ),

    logic_or: $ => seq(
      $.logic_and,
      repeat(
        seq(
          "||",
          $.logic_and
        )
      )
    ),

    logic_and: $ => seq(
      $.equality,
      repeat(
        seq(
          "&&",
          $.equality
        )
      )
    ),

    equality: $ => seq(
      $.comparison,
      repeat(
        seq(
          choice("!=", "=="),
          $.comparison
        )
      )
    ),

    comparison: $ => seq(
      $.term,
      repeat(
        seq(
          choice(
            ">",
            ">=",
            "<",
            "<="
          ),
          $.term
        )
      )
    ),

    term: $ => prec.left(seq(
      $.factor,
      repeat(
        seq(
          choice("-", "+"),
          $.factor
        )
      )
    )),

    factor: $ => prec.left(seq(
      $.unary,
      repeat(
        seq(
          choice("/", "*"),
          $.factor
        )
      )
    )),

    unary: $ => choice(
      seq(
        choice(
          "!", "-"
        ),
        choice($.unary, $.call)
      )
    ),

    call: $ => prec.left(seq(
      $.primary,
      repeat(
        choice(
          seq("(", optional($.arguments), ")"),
          seq(".", $.identifier)
        )
      )
    )),

    primary: $ => choice(
      "true", "false", "nil", "self",
      $.number,
      $.string,
      $.identifier,
      seq("(", $.expr, ")"),
      seq("super", ".", $.identifier)
    ),

    function: $ => seq(
      field('name', $.identifier),
      "(",
      optional($.parameters),
      ")",
      $.block
    ),

    init: $ => seq(
      "init",
      "(",
      optional($.parameters),
      ")",
      $.block
    ),

    parameters: $ => seq(
      $.identifier,
      repeat(
        seq(
          ",",
          $.identifier
        )
      )
    ),

    arguments: $ => seq(
      $.expr,
      repeat(
        seq(
          ",",
          $.expr
        )
      )
    ),

    string: _ => /"[^"]*"/,
    number: _ => /\d+/,
    identifier: _ => /[a-zA-Z_]\w*/,
  }
});

