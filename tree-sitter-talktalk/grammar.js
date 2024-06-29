module.exports = grammar({
  name: 'TalkTalk',

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
      $.if_statement,
      $.while_statement
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
      repeat(seq(choice('==', '!='), $.comparison))
    ),

    comparison: $ => seq(
      $.term,
      repeat(seq(choice('>', '>=', '<', '<='), $.term))
    ),

    term: $ => seq(
      $.factor,
      repeat(seq(choice('+', '-'), $.factor))
    ),

    factor: $ => seq(
      $.unary_expression,
      repeat(seq(choice('*', '/'), $.unary_expression))
    ),

    logic_or: $ => seq(
      $.logic_and,
      repeat(seq('||', $.equality))
    ),

    logic_and: $ => seq(
      $.equality,
      repeat(seq('&&', $.equality))
    ),

    while_statement: $ => seq(
      'while',
      $.expression,
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
      choice('-', '!'),
      $.call
    )),

    primary_expression: $ => choice(
      $.number_literal,
      'nil',
      $.string_literal,
      $.boolean_literal,
      $.variable,
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

    binary_operator: _ => choice('+', '-', '*', '/', '==', '!=', '<', '<=', '>', '>='),

    boolean_literal: _ => choice('true', 'false'),

    number_literal: _ => /\d+(\.\d+)?/,

    string_literal: _ => /"[^"]*"/,

    variable: _ => /[a-zA-Z_]\w*/,
  }
});

