module.exports = grammar({
  name: 'swlox',

  rules: {
    source_file: $ => repeat($.declaration),

    declaration: $ => choice(
      $.variable_declaration,
      $.statement
    ),

    block: $ => seq(
      "{",
      repeat($.declaration),
      "}"
    ),

    statement: $ => choice(
      $.print_statement,
      $.expression_statement,
      $.assignment_statement,
      $.block,
      $.if_statement
    ),

    if_statement: $ => seq(
      'if',
      $.expression,
      $.block,
      optional($.else_statement)
    ),

    else_statement: $ => seq(
      'else',
      $.block
    ),

    equality: $ => seq(
      $.comparison,
      repeat(seq('==', $.comparison))
    ),

    logic_or: $ => seq(
      $.logic_and
      repeat(seq('||', $.equality))
    ),

    logic_and: $ => seq(
      $.equality,
      repeat(seq('&&', $.equality))
    ),

    while_statement: $ => seq(
      'while',
      $.block
    ),

    expression_statement: $ => seq(
      $.expression,
      ';'
    ),

    expression: $ => choice(
      $.binary_expression,
      $.unary_expression,
      $.primary_expression,
      $.grouped_expression
    ),

    grouped_expression: $ => seq(
      '(',
      $.expression,
      ')'
    ),

    binary_expression: $ => prec.left(1, seq(
      $.expression,
      $.binary_operator,
      $.expression
    )),

    print_statement: $ => seq(
      'print',
      $.expression,
      ';'
    ),

    assignment_statement: $ => seq(
      $.variable,
      '=',
      $.expression,
      ';'
    ),

    unary_expression: $ => prec.left(2, seq(
      $.unary_operator,
      $.expression
    )),

    primary_expression: $ => choice(
      $.number_literal,
      $.string_literal,
      $.variable
    ),

    variable_declaration: $ => seq(
      'var',
      $.variable,
      '=',
      $.expression,
      ';'
    ),

    call: $ => seq($.primary_expression, repeat1(seq('(', optional($.arguments), ')' ))),
    arguments: $ => seq($.expression, repeat(seq(',', $.expression))),

    unary_operator: $ => choice('-', '!', $.call),

    binary_operator: _ => choice('+', '-', '*', '/', '==', '!=', '<', '<=', '>', '>='),

    boolean_literal: _ => choice('true', 'false'),

    number_literal: _ => /\d+(\.\d+)?/,

    string_literal: _ => /"[^"]*"/,

    variable: _ => /[a-zA-Z_]\w*/,
  }
});

