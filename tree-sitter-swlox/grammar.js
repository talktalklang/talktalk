module.exports = grammar({
  name: 'swlox',

  rules: {
    // TODO: add the actual grammar rules
    source_file: $ => repeat($.declaration),

    declaration: $ => choice(
      $.variable_declaration,
      $.statement
    ),

    statement: $ => choice(
      $.print_statement,
      $.expression_statement,
      $.assignment_statement
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

    unary_operator: _ => choice('-', '!'),

    binary_operator: _ => choice('+', '-', '*', '/', '==', '!=', '<', '<=', '>', '>='),

    number_literal: _ => /\d+(\.\d+)?/,

    string_literal: _ => /"[^"]*"/,

    variable: _ => /[a-zA-Z_]\w*/,
  }
});

