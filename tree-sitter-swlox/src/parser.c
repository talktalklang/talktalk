#include "tree_sitter/parser.h"

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#define LANGUAGE_VERSION 14
#define STATE_COUNT 46
#define LARGE_STATE_COUNT 6
#define SYMBOL_COUNT 45
#define ALIAS_COUNT 0
#define TOKEN_COUNT 27
#define EXTERNAL_TOKEN_COUNT 0
#define FIELD_COUNT 0
#define MAX_ALIAS_SEQUENCE_LENGTH 6
#define PRODUCTION_ID_COUNT 1

enum ts_symbol_identifiers {
  anon_sym_LBRACE = 1,
  anon_sym_RBRACE = 2,
  anon_sym_if = 3,
  anon_sym_else = 4,
  anon_sym_SEMI = 5,
  anon_sym_LPAREN = 6,
  anon_sym_RPAREN = 7,
  anon_sym_print = 8,
  anon_sym_EQ = 9,
  anon_sym_var = 10,
  anon_sym_DASH = 11,
  anon_sym_BANG = 12,
  anon_sym_PLUS = 13,
  anon_sym_STAR = 14,
  anon_sym_SLASH = 15,
  anon_sym_EQ_EQ = 16,
  anon_sym_BANG_EQ = 17,
  anon_sym_LT = 18,
  anon_sym_LT_EQ = 19,
  anon_sym_GT = 20,
  anon_sym_GT_EQ = 21,
  anon_sym_true = 22,
  anon_sym_false = 23,
  sym_number_literal = 24,
  sym_string_literal = 25,
  sym_variable = 26,
  sym_source_file = 27,
  sym_declaration = 28,
  sym_block = 29,
  sym_statement = 30,
  sym_if_statement = 31,
  sym_else_statement = 32,
  sym_expression_statement = 33,
  sym_expression = 34,
  sym_grouped_expression = 35,
  sym_binary_expression = 36,
  sym_print_statement = 37,
  sym_assignment_statement = 38,
  sym_unary_expression = 39,
  sym_primary_expression = 40,
  sym_variable_declaration = 41,
  sym_unary_operator = 42,
  sym_binary_operator = 43,
  aux_sym_source_file_repeat1 = 44,
};

static const char * const ts_symbol_names[] = {
  [ts_builtin_sym_end] = "end",
  [anon_sym_LBRACE] = "{",
  [anon_sym_RBRACE] = "}",
  [anon_sym_if] = "if",
  [anon_sym_else] = "else",
  [anon_sym_SEMI] = ";",
  [anon_sym_LPAREN] = "(",
  [anon_sym_RPAREN] = ")",
  [anon_sym_print] = "print",
  [anon_sym_EQ] = "=",
  [anon_sym_var] = "var",
  [anon_sym_DASH] = "-",
  [anon_sym_BANG] = "!",
  [anon_sym_PLUS] = "+",
  [anon_sym_STAR] = "*",
  [anon_sym_SLASH] = "/",
  [anon_sym_EQ_EQ] = "==",
  [anon_sym_BANG_EQ] = "!=",
  [anon_sym_LT] = "<",
  [anon_sym_LT_EQ] = "<=",
  [anon_sym_GT] = ">",
  [anon_sym_GT_EQ] = ">=",
  [anon_sym_true] = "true",
  [anon_sym_false] = "false",
  [sym_number_literal] = "number_literal",
  [sym_string_literal] = "string_literal",
  [sym_variable] = "variable",
  [sym_source_file] = "source_file",
  [sym_declaration] = "declaration",
  [sym_block] = "block",
  [sym_statement] = "statement",
  [sym_if_statement] = "if_statement",
  [sym_else_statement] = "else_statement",
  [sym_expression_statement] = "expression_statement",
  [sym_expression] = "expression",
  [sym_grouped_expression] = "grouped_expression",
  [sym_binary_expression] = "binary_expression",
  [sym_print_statement] = "print_statement",
  [sym_assignment_statement] = "assignment_statement",
  [sym_unary_expression] = "unary_expression",
  [sym_primary_expression] = "primary_expression",
  [sym_variable_declaration] = "variable_declaration",
  [sym_unary_operator] = "unary_operator",
  [sym_binary_operator] = "binary_operator",
  [aux_sym_source_file_repeat1] = "source_file_repeat1",
};

static const TSSymbol ts_symbol_map[] = {
  [ts_builtin_sym_end] = ts_builtin_sym_end,
  [anon_sym_LBRACE] = anon_sym_LBRACE,
  [anon_sym_RBRACE] = anon_sym_RBRACE,
  [anon_sym_if] = anon_sym_if,
  [anon_sym_else] = anon_sym_else,
  [anon_sym_SEMI] = anon_sym_SEMI,
  [anon_sym_LPAREN] = anon_sym_LPAREN,
  [anon_sym_RPAREN] = anon_sym_RPAREN,
  [anon_sym_print] = anon_sym_print,
  [anon_sym_EQ] = anon_sym_EQ,
  [anon_sym_var] = anon_sym_var,
  [anon_sym_DASH] = anon_sym_DASH,
  [anon_sym_BANG] = anon_sym_BANG,
  [anon_sym_PLUS] = anon_sym_PLUS,
  [anon_sym_STAR] = anon_sym_STAR,
  [anon_sym_SLASH] = anon_sym_SLASH,
  [anon_sym_EQ_EQ] = anon_sym_EQ_EQ,
  [anon_sym_BANG_EQ] = anon_sym_BANG_EQ,
  [anon_sym_LT] = anon_sym_LT,
  [anon_sym_LT_EQ] = anon_sym_LT_EQ,
  [anon_sym_GT] = anon_sym_GT,
  [anon_sym_GT_EQ] = anon_sym_GT_EQ,
  [anon_sym_true] = anon_sym_true,
  [anon_sym_false] = anon_sym_false,
  [sym_number_literal] = sym_number_literal,
  [sym_string_literal] = sym_string_literal,
  [sym_variable] = sym_variable,
  [sym_source_file] = sym_source_file,
  [sym_declaration] = sym_declaration,
  [sym_block] = sym_block,
  [sym_statement] = sym_statement,
  [sym_if_statement] = sym_if_statement,
  [sym_else_statement] = sym_else_statement,
  [sym_expression_statement] = sym_expression_statement,
  [sym_expression] = sym_expression,
  [sym_grouped_expression] = sym_grouped_expression,
  [sym_binary_expression] = sym_binary_expression,
  [sym_print_statement] = sym_print_statement,
  [sym_assignment_statement] = sym_assignment_statement,
  [sym_unary_expression] = sym_unary_expression,
  [sym_primary_expression] = sym_primary_expression,
  [sym_variable_declaration] = sym_variable_declaration,
  [sym_unary_operator] = sym_unary_operator,
  [sym_binary_operator] = sym_binary_operator,
  [aux_sym_source_file_repeat1] = aux_sym_source_file_repeat1,
};

static const TSSymbolMetadata ts_symbol_metadata[] = {
  [ts_builtin_sym_end] = {
    .visible = false,
    .named = true,
  },
  [anon_sym_LBRACE] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_RBRACE] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_if] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_else] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_SEMI] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_LPAREN] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_RPAREN] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_print] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_EQ] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_var] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_DASH] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_BANG] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_PLUS] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_STAR] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_SLASH] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_EQ_EQ] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_BANG_EQ] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_LT] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_LT_EQ] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_GT] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_GT_EQ] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_true] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_false] = {
    .visible = true,
    .named = false,
  },
  [sym_number_literal] = {
    .visible = true,
    .named = true,
  },
  [sym_string_literal] = {
    .visible = true,
    .named = true,
  },
  [sym_variable] = {
    .visible = true,
    .named = true,
  },
  [sym_source_file] = {
    .visible = true,
    .named = true,
  },
  [sym_declaration] = {
    .visible = true,
    .named = true,
  },
  [sym_block] = {
    .visible = true,
    .named = true,
  },
  [sym_statement] = {
    .visible = true,
    .named = true,
  },
  [sym_if_statement] = {
    .visible = true,
    .named = true,
  },
  [sym_else_statement] = {
    .visible = true,
    .named = true,
  },
  [sym_expression_statement] = {
    .visible = true,
    .named = true,
  },
  [sym_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_grouped_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_binary_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_print_statement] = {
    .visible = true,
    .named = true,
  },
  [sym_assignment_statement] = {
    .visible = true,
    .named = true,
  },
  [sym_unary_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_primary_expression] = {
    .visible = true,
    .named = true,
  },
  [sym_variable_declaration] = {
    .visible = true,
    .named = true,
  },
  [sym_unary_operator] = {
    .visible = true,
    .named = true,
  },
  [sym_binary_operator] = {
    .visible = true,
    .named = true,
  },
  [aux_sym_source_file_repeat1] = {
    .visible = false,
    .named = false,
  },
};

static const TSSymbol ts_alias_sequences[PRODUCTION_ID_COUNT][MAX_ALIAS_SEQUENCE_LENGTH] = {
  [0] = {0},
};

static const uint16_t ts_non_terminal_alias_map[] = {
  0,
};

static const TSStateId ts_primary_state_ids[STATE_COUNT] = {
  [0] = 0,
  [1] = 1,
  [2] = 2,
  [3] = 3,
  [4] = 4,
  [5] = 5,
  [6] = 6,
  [7] = 7,
  [8] = 8,
  [9] = 9,
  [10] = 10,
  [11] = 11,
  [12] = 12,
  [13] = 13,
  [14] = 14,
  [15] = 15,
  [16] = 16,
  [17] = 17,
  [18] = 18,
  [19] = 19,
  [20] = 20,
  [21] = 21,
  [22] = 22,
  [23] = 23,
  [24] = 24,
  [25] = 25,
  [26] = 26,
  [27] = 27,
  [28] = 28,
  [29] = 29,
  [30] = 30,
  [31] = 31,
  [32] = 32,
  [33] = 33,
  [34] = 34,
  [35] = 35,
  [36] = 36,
  [37] = 37,
  [38] = 38,
  [39] = 39,
  [40] = 40,
  [41] = 41,
  [42] = 42,
  [43] = 43,
  [44] = 44,
  [45] = 45,
};

static bool ts_lex(TSLexer *lexer, TSStateId state) {
  START_LEXER();
  eof = lexer->eof(lexer);
  switch (state) {
    case 0:
      if (eof) ADVANCE(9);
      ADVANCE_MAP(
        '!', 22,
        '"', 4,
        '(', 15,
        ')', 16,
        '*', 24,
        '+', 23,
        '-', 20,
        '/', 25,
        ';', 14,
        '<', 28,
        '=', 18,
        '>', 30,
        'e', 44,
        'f', 38,
        'i', 42,
        'p', 47,
        't', 48,
        'v', 37,
        '{', 10,
        '}', 11,
      );
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(0);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(34);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 1:
      if (lookahead == '!') ADVANCE(21);
      if (lookahead == '"') ADVANCE(4);
      if (lookahead == '(') ADVANCE(15);
      if (lookahead == '-') ADVANCE(20);
      if (lookahead == 'i') ADVANCE(42);
      if (lookahead == 'p') ADVANCE(47);
      if (lookahead == '{') ADVANCE(10);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(1);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(34);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 2:
      if (lookahead == '!') ADVANCE(21);
      if (lookahead == '"') ADVANCE(4);
      if (lookahead == '(') ADVANCE(15);
      if (lookahead == '-') ADVANCE(20);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(2);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(34);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 3:
      ADVANCE_MAP(
        '!', 5,
        ')', 16,
        '*', 24,
        '+', 23,
        '-', 20,
        '/', 25,
        ';', 14,
        '<', 28,
        '=', 18,
        '>', 30,
        '{', 10,
      );
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(3);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 4:
      if (lookahead == '"') ADVANCE(36);
      if (lookahead != 0) ADVANCE(4);
      END_STATE();
    case 5:
      if (lookahead == '=') ADVANCE(27);
      END_STATE();
    case 6:
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(35);
      END_STATE();
    case 7:
      if (eof) ADVANCE(9);
      ADVANCE_MAP(
        '!', 21,
        '"', 4,
        '(', 15,
        '-', 20,
        'e', 44,
        'i', 42,
        'p', 47,
        'v', 37,
        '{', 10,
        '}', 11,
      );
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(7);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(34);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 8:
      if (eof) ADVANCE(9);
      ADVANCE_MAP(
        '!', 21,
        '"', 4,
        '(', 15,
        '-', 20,
        'i', 42,
        'p', 47,
        'v', 37,
        '{', 10,
        '}', 11,
      );
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(8);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(34);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 9:
      ACCEPT_TOKEN(ts_builtin_sym_end);
      END_STATE();
    case 10:
      ACCEPT_TOKEN(anon_sym_LBRACE);
      END_STATE();
    case 11:
      ACCEPT_TOKEN(anon_sym_RBRACE);
      END_STATE();
    case 12:
      ACCEPT_TOKEN(anon_sym_if);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 13:
      ACCEPT_TOKEN(anon_sym_else);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 14:
      ACCEPT_TOKEN(anon_sym_SEMI);
      END_STATE();
    case 15:
      ACCEPT_TOKEN(anon_sym_LPAREN);
      END_STATE();
    case 16:
      ACCEPT_TOKEN(anon_sym_RPAREN);
      END_STATE();
    case 17:
      ACCEPT_TOKEN(anon_sym_print);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 18:
      ACCEPT_TOKEN(anon_sym_EQ);
      if (lookahead == '=') ADVANCE(26);
      END_STATE();
    case 19:
      ACCEPT_TOKEN(anon_sym_var);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 20:
      ACCEPT_TOKEN(anon_sym_DASH);
      END_STATE();
    case 21:
      ACCEPT_TOKEN(anon_sym_BANG);
      END_STATE();
    case 22:
      ACCEPT_TOKEN(anon_sym_BANG);
      if (lookahead == '=') ADVANCE(27);
      END_STATE();
    case 23:
      ACCEPT_TOKEN(anon_sym_PLUS);
      END_STATE();
    case 24:
      ACCEPT_TOKEN(anon_sym_STAR);
      END_STATE();
    case 25:
      ACCEPT_TOKEN(anon_sym_SLASH);
      END_STATE();
    case 26:
      ACCEPT_TOKEN(anon_sym_EQ_EQ);
      END_STATE();
    case 27:
      ACCEPT_TOKEN(anon_sym_BANG_EQ);
      END_STATE();
    case 28:
      ACCEPT_TOKEN(anon_sym_LT);
      if (lookahead == '=') ADVANCE(29);
      END_STATE();
    case 29:
      ACCEPT_TOKEN(anon_sym_LT_EQ);
      END_STATE();
    case 30:
      ACCEPT_TOKEN(anon_sym_GT);
      if (lookahead == '=') ADVANCE(31);
      END_STATE();
    case 31:
      ACCEPT_TOKEN(anon_sym_GT_EQ);
      END_STATE();
    case 32:
      ACCEPT_TOKEN(anon_sym_true);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 33:
      ACCEPT_TOKEN(anon_sym_false);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 34:
      ACCEPT_TOKEN(sym_number_literal);
      if (lookahead == '.') ADVANCE(6);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(34);
      END_STATE();
    case 35:
      ACCEPT_TOKEN(sym_number_literal);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(35);
      END_STATE();
    case 36:
      ACCEPT_TOKEN(sym_string_literal);
      END_STATE();
    case 37:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'a') ADVANCE(49);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('b' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 38:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'a') ADVANCE(45);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('b' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 39:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'e') ADVANCE(13);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 40:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'e') ADVANCE(32);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 41:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'e') ADVANCE(33);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 42:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'f') ADVANCE(12);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 43:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'i') ADVANCE(46);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 44:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'l') ADVANCE(50);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 45:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'l') ADVANCE(51);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 46:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'n') ADVANCE(52);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 47:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'r') ADVANCE(43);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 48:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'r') ADVANCE(53);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 49:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'r') ADVANCE(19);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 50:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 's') ADVANCE(39);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 51:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 's') ADVANCE(41);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 52:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 't') ADVANCE(17);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 53:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'u') ADVANCE(40);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    case 54:
      ACCEPT_TOKEN(sym_variable);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(54);
      END_STATE();
    default:
      return false;
  }
}

static const TSLexMode ts_lex_modes[STATE_COUNT] = {
  [0] = {.lex_state = 0},
  [1] = {.lex_state = 8},
  [2] = {.lex_state = 8},
  [3] = {.lex_state = 8},
  [4] = {.lex_state = 8},
  [5] = {.lex_state = 8},
  [6] = {.lex_state = 1},
  [7] = {.lex_state = 1},
  [8] = {.lex_state = 7},
  [9] = {.lex_state = 3},
  [10] = {.lex_state = 3},
  [11] = {.lex_state = 3},
  [12] = {.lex_state = 3},
  [13] = {.lex_state = 3},
  [14] = {.lex_state = 2},
  [15] = {.lex_state = 2},
  [16] = {.lex_state = 3},
  [17] = {.lex_state = 2},
  [18] = {.lex_state = 8},
  [19] = {.lex_state = 3},
  [20] = {.lex_state = 3},
  [21] = {.lex_state = 3},
  [22] = {.lex_state = 8},
  [23] = {.lex_state = 2},
  [24] = {.lex_state = 8},
  [25] = {.lex_state = 2},
  [26] = {.lex_state = 2},
  [27] = {.lex_state = 8},
  [28] = {.lex_state = 8},
  [29] = {.lex_state = 8},
  [30] = {.lex_state = 8},
  [31] = {.lex_state = 3},
  [32] = {.lex_state = 8},
  [33] = {.lex_state = 8},
  [34] = {.lex_state = 3},
  [35] = {.lex_state = 2},
  [36] = {.lex_state = 8},
  [37] = {.lex_state = 3},
  [38] = {.lex_state = 2},
  [39] = {.lex_state = 2},
  [40] = {.lex_state = 0},
  [41] = {.lex_state = 0},
  [42] = {.lex_state = 0},
  [43] = {.lex_state = 0},
  [44] = {.lex_state = 0},
  [45] = {.lex_state = 3},
};

static const uint16_t ts_parse_table[LARGE_STATE_COUNT][SYMBOL_COUNT] = {
  [0] = {
    [ts_builtin_sym_end] = ACTIONS(1),
    [anon_sym_LBRACE] = ACTIONS(1),
    [anon_sym_RBRACE] = ACTIONS(1),
    [anon_sym_if] = ACTIONS(1),
    [anon_sym_else] = ACTIONS(1),
    [anon_sym_SEMI] = ACTIONS(1),
    [anon_sym_LPAREN] = ACTIONS(1),
    [anon_sym_RPAREN] = ACTIONS(1),
    [anon_sym_print] = ACTIONS(1),
    [anon_sym_EQ] = ACTIONS(1),
    [anon_sym_var] = ACTIONS(1),
    [anon_sym_DASH] = ACTIONS(1),
    [anon_sym_BANG] = ACTIONS(1),
    [anon_sym_PLUS] = ACTIONS(1),
    [anon_sym_STAR] = ACTIONS(1),
    [anon_sym_SLASH] = ACTIONS(1),
    [anon_sym_EQ_EQ] = ACTIONS(1),
    [anon_sym_BANG_EQ] = ACTIONS(1),
    [anon_sym_LT] = ACTIONS(1),
    [anon_sym_LT_EQ] = ACTIONS(1),
    [anon_sym_GT] = ACTIONS(1),
    [anon_sym_GT_EQ] = ACTIONS(1),
    [anon_sym_true] = ACTIONS(1),
    [anon_sym_false] = ACTIONS(1),
    [sym_number_literal] = ACTIONS(1),
    [sym_string_literal] = ACTIONS(1),
    [sym_variable] = ACTIONS(1),
  },
  [1] = {
    [sym_source_file] = STATE(42),
    [sym_declaration] = STATE(5),
    [sym_block] = STATE(28),
    [sym_statement] = STATE(22),
    [sym_if_statement] = STATE(28),
    [sym_expression_statement] = STATE(28),
    [sym_expression] = STATE(16),
    [sym_grouped_expression] = STATE(11),
    [sym_binary_expression] = STATE(11),
    [sym_print_statement] = STATE(28),
    [sym_assignment_statement] = STATE(28),
    [sym_unary_expression] = STATE(11),
    [sym_primary_expression] = STATE(11),
    [sym_variable_declaration] = STATE(22),
    [sym_unary_operator] = STATE(17),
    [aux_sym_source_file_repeat1] = STATE(5),
    [ts_builtin_sym_end] = ACTIONS(3),
    [anon_sym_LBRACE] = ACTIONS(5),
    [anon_sym_if] = ACTIONS(7),
    [anon_sym_LPAREN] = ACTIONS(9),
    [anon_sym_print] = ACTIONS(11),
    [anon_sym_var] = ACTIONS(13),
    [anon_sym_DASH] = ACTIONS(15),
    [anon_sym_BANG] = ACTIONS(15),
    [sym_number_literal] = ACTIONS(17),
    [sym_string_literal] = ACTIONS(17),
    [sym_variable] = ACTIONS(19),
  },
  [2] = {
    [sym_declaration] = STATE(2),
    [sym_block] = STATE(28),
    [sym_statement] = STATE(22),
    [sym_if_statement] = STATE(28),
    [sym_expression_statement] = STATE(28),
    [sym_expression] = STATE(16),
    [sym_grouped_expression] = STATE(11),
    [sym_binary_expression] = STATE(11),
    [sym_print_statement] = STATE(28),
    [sym_assignment_statement] = STATE(28),
    [sym_unary_expression] = STATE(11),
    [sym_primary_expression] = STATE(11),
    [sym_variable_declaration] = STATE(22),
    [sym_unary_operator] = STATE(17),
    [aux_sym_source_file_repeat1] = STATE(2),
    [ts_builtin_sym_end] = ACTIONS(21),
    [anon_sym_LBRACE] = ACTIONS(23),
    [anon_sym_RBRACE] = ACTIONS(21),
    [anon_sym_if] = ACTIONS(26),
    [anon_sym_LPAREN] = ACTIONS(29),
    [anon_sym_print] = ACTIONS(32),
    [anon_sym_var] = ACTIONS(35),
    [anon_sym_DASH] = ACTIONS(38),
    [anon_sym_BANG] = ACTIONS(38),
    [sym_number_literal] = ACTIONS(41),
    [sym_string_literal] = ACTIONS(41),
    [sym_variable] = ACTIONS(44),
  },
  [3] = {
    [sym_declaration] = STATE(4),
    [sym_block] = STATE(28),
    [sym_statement] = STATE(22),
    [sym_if_statement] = STATE(28),
    [sym_expression_statement] = STATE(28),
    [sym_expression] = STATE(16),
    [sym_grouped_expression] = STATE(11),
    [sym_binary_expression] = STATE(11),
    [sym_print_statement] = STATE(28),
    [sym_assignment_statement] = STATE(28),
    [sym_unary_expression] = STATE(11),
    [sym_primary_expression] = STATE(11),
    [sym_variable_declaration] = STATE(22),
    [sym_unary_operator] = STATE(17),
    [aux_sym_source_file_repeat1] = STATE(4),
    [anon_sym_LBRACE] = ACTIONS(5),
    [anon_sym_RBRACE] = ACTIONS(47),
    [anon_sym_if] = ACTIONS(7),
    [anon_sym_LPAREN] = ACTIONS(9),
    [anon_sym_print] = ACTIONS(11),
    [anon_sym_var] = ACTIONS(13),
    [anon_sym_DASH] = ACTIONS(15),
    [anon_sym_BANG] = ACTIONS(15),
    [sym_number_literal] = ACTIONS(17),
    [sym_string_literal] = ACTIONS(17),
    [sym_variable] = ACTIONS(19),
  },
  [4] = {
    [sym_declaration] = STATE(2),
    [sym_block] = STATE(28),
    [sym_statement] = STATE(22),
    [sym_if_statement] = STATE(28),
    [sym_expression_statement] = STATE(28),
    [sym_expression] = STATE(16),
    [sym_grouped_expression] = STATE(11),
    [sym_binary_expression] = STATE(11),
    [sym_print_statement] = STATE(28),
    [sym_assignment_statement] = STATE(28),
    [sym_unary_expression] = STATE(11),
    [sym_primary_expression] = STATE(11),
    [sym_variable_declaration] = STATE(22),
    [sym_unary_operator] = STATE(17),
    [aux_sym_source_file_repeat1] = STATE(2),
    [anon_sym_LBRACE] = ACTIONS(5),
    [anon_sym_RBRACE] = ACTIONS(49),
    [anon_sym_if] = ACTIONS(7),
    [anon_sym_LPAREN] = ACTIONS(9),
    [anon_sym_print] = ACTIONS(11),
    [anon_sym_var] = ACTIONS(13),
    [anon_sym_DASH] = ACTIONS(15),
    [anon_sym_BANG] = ACTIONS(15),
    [sym_number_literal] = ACTIONS(17),
    [sym_string_literal] = ACTIONS(17),
    [sym_variable] = ACTIONS(19),
  },
  [5] = {
    [sym_declaration] = STATE(2),
    [sym_block] = STATE(28),
    [sym_statement] = STATE(22),
    [sym_if_statement] = STATE(28),
    [sym_expression_statement] = STATE(28),
    [sym_expression] = STATE(16),
    [sym_grouped_expression] = STATE(11),
    [sym_binary_expression] = STATE(11),
    [sym_print_statement] = STATE(28),
    [sym_assignment_statement] = STATE(28),
    [sym_unary_expression] = STATE(11),
    [sym_primary_expression] = STATE(11),
    [sym_variable_declaration] = STATE(22),
    [sym_unary_operator] = STATE(17),
    [aux_sym_source_file_repeat1] = STATE(2),
    [ts_builtin_sym_end] = ACTIONS(51),
    [anon_sym_LBRACE] = ACTIONS(5),
    [anon_sym_if] = ACTIONS(7),
    [anon_sym_LPAREN] = ACTIONS(9),
    [anon_sym_print] = ACTIONS(11),
    [anon_sym_var] = ACTIONS(13),
    [anon_sym_DASH] = ACTIONS(15),
    [anon_sym_BANG] = ACTIONS(15),
    [sym_number_literal] = ACTIONS(17),
    [sym_string_literal] = ACTIONS(17),
    [sym_variable] = ACTIONS(19),
  },
};

static const uint16_t ts_small_parse_table[] = {
  [0] = 12,
    ACTIONS(5), 1,
      anon_sym_LBRACE,
    ACTIONS(7), 1,
      anon_sym_if,
    ACTIONS(9), 1,
      anon_sym_LPAREN,
    ACTIONS(11), 1,
      anon_sym_print,
    ACTIONS(19), 1,
      sym_variable,
    STATE(16), 1,
      sym_expression,
    STATE(17), 1,
      sym_unary_operator,
    STATE(44), 1,
      sym_statement,
    ACTIONS(15), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 2,
      sym_number_literal,
      sym_string_literal,
    STATE(11), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
    STATE(28), 5,
      sym_block,
      sym_if_statement,
      sym_expression_statement,
      sym_print_statement,
      sym_assignment_statement,
  [46] = 12,
    ACTIONS(5), 1,
      anon_sym_LBRACE,
    ACTIONS(7), 1,
      anon_sym_if,
    ACTIONS(9), 1,
      anon_sym_LPAREN,
    ACTIONS(11), 1,
      anon_sym_print,
    ACTIONS(19), 1,
      sym_variable,
    STATE(16), 1,
      sym_expression,
    STATE(17), 1,
      sym_unary_operator,
    STATE(43), 1,
      sym_statement,
    ACTIONS(15), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 2,
      sym_number_literal,
      sym_string_literal,
    STATE(11), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
    STATE(28), 5,
      sym_block,
      sym_if_statement,
      sym_expression_statement,
      sym_print_statement,
      sym_assignment_statement,
  [92] = 4,
    ACTIONS(57), 1,
      anon_sym_else,
    STATE(36), 1,
      sym_else_statement,
    ACTIONS(55), 4,
      anon_sym_if,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(53), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [115] = 3,
    STATE(26), 1,
      sym_binary_operator,
    ACTIONS(61), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(59), 11,
      anon_sym_LBRACE,
      anon_sym_SEMI,
      anon_sym_RPAREN,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [136] = 3,
    STATE(26), 1,
      sym_binary_operator,
    ACTIONS(65), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(63), 11,
      anon_sym_LBRACE,
      anon_sym_SEMI,
      anon_sym_RPAREN,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [157] = 2,
    ACTIONS(69), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(67), 11,
      anon_sym_LBRACE,
      anon_sym_SEMI,
      anon_sym_RPAREN,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [175] = 2,
    ACTIONS(73), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(71), 11,
      anon_sym_LBRACE,
      anon_sym_SEMI,
      anon_sym_RPAREN,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [193] = 2,
    ACTIONS(77), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(75), 11,
      anon_sym_LBRACE,
      anon_sym_SEMI,
      anon_sym_RPAREN,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [211] = 6,
    ACTIONS(9), 1,
      anon_sym_LPAREN,
    STATE(17), 1,
      sym_unary_operator,
    STATE(37), 1,
      sym_expression,
    ACTIONS(15), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(11), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [236] = 6,
    ACTIONS(9), 1,
      anon_sym_LPAREN,
    STATE(17), 1,
      sym_unary_operator,
    STATE(19), 1,
      sym_expression,
    ACTIONS(15), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(11), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [261] = 4,
    ACTIONS(79), 1,
      anon_sym_SEMI,
    STATE(26), 1,
      sym_binary_operator,
    ACTIONS(83), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(81), 8,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [282] = 6,
    ACTIONS(9), 1,
      anon_sym_LPAREN,
    STATE(10), 1,
      sym_expression,
    STATE(17), 1,
      sym_unary_operator,
    ACTIONS(15), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(11), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [307] = 2,
    ACTIONS(87), 4,
      anon_sym_if,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(85), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [324] = 4,
    ACTIONS(89), 1,
      anon_sym_LBRACE,
    STATE(26), 1,
      sym_binary_operator,
    ACTIONS(83), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(81), 8,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [345] = 4,
    ACTIONS(91), 1,
      anon_sym_RPAREN,
    STATE(26), 1,
      sym_binary_operator,
    ACTIONS(83), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(81), 8,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [366] = 4,
    ACTIONS(93), 1,
      anon_sym_SEMI,
    STATE(26), 1,
      sym_binary_operator,
    ACTIONS(83), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(81), 8,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [387] = 2,
    ACTIONS(97), 4,
      anon_sym_if,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(95), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [404] = 6,
    ACTIONS(9), 1,
      anon_sym_LPAREN,
    STATE(17), 1,
      sym_unary_operator,
    STATE(34), 1,
      sym_expression,
    ACTIONS(15), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(11), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [429] = 2,
    ACTIONS(101), 4,
      anon_sym_if,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(99), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [446] = 6,
    ACTIONS(9), 1,
      anon_sym_LPAREN,
    STATE(17), 1,
      sym_unary_operator,
    STATE(21), 1,
      sym_expression,
    ACTIONS(15), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(11), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [471] = 6,
    ACTIONS(9), 1,
      anon_sym_LPAREN,
    STATE(9), 1,
      sym_expression,
    STATE(17), 1,
      sym_unary_operator,
    ACTIONS(15), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(11), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [496] = 2,
    ACTIONS(105), 4,
      anon_sym_if,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(103), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [513] = 2,
    ACTIONS(109), 4,
      anon_sym_if,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(107), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [530] = 2,
    ACTIONS(113), 4,
      anon_sym_if,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(111), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [547] = 2,
    ACTIONS(117), 4,
      anon_sym_if,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(115), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [564] = 3,
    ACTIONS(119), 1,
      anon_sym_EQ,
    ACTIONS(77), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(75), 9,
      anon_sym_SEMI,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [583] = 2,
    ACTIONS(123), 4,
      anon_sym_if,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(121), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [600] = 2,
    ACTIONS(127), 4,
      anon_sym_if,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(125), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [617] = 4,
    ACTIONS(129), 1,
      anon_sym_SEMI,
    STATE(26), 1,
      sym_binary_operator,
    ACTIONS(83), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(81), 8,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [638] = 6,
    ACTIONS(9), 1,
      anon_sym_LPAREN,
    STATE(17), 1,
      sym_unary_operator,
    STATE(20), 1,
      sym_expression,
    ACTIONS(15), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(11), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [663] = 2,
    ACTIONS(133), 4,
      anon_sym_if,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(131), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [680] = 4,
    ACTIONS(135), 1,
      anon_sym_SEMI,
    STATE(26), 1,
      sym_binary_operator,
    ACTIONS(83), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(81), 8,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [701] = 1,
    ACTIONS(137), 6,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
  [710] = 1,
    ACTIONS(139), 6,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
  [719] = 1,
    ACTIONS(141), 1,
      anon_sym_EQ,
  [723] = 1,
    ACTIONS(143), 1,
      anon_sym_LBRACE,
  [727] = 1,
    ACTIONS(145), 1,
      ts_builtin_sym_end,
  [731] = 1,
    ACTIONS(147), 1,
      anon_sym_RBRACE,
  [735] = 1,
    ACTIONS(149), 1,
      anon_sym_RBRACE,
  [739] = 1,
    ACTIONS(151), 1,
      sym_variable,
};

static const uint32_t ts_small_parse_table_map[] = {
  [SMALL_STATE(6)] = 0,
  [SMALL_STATE(7)] = 46,
  [SMALL_STATE(8)] = 92,
  [SMALL_STATE(9)] = 115,
  [SMALL_STATE(10)] = 136,
  [SMALL_STATE(11)] = 157,
  [SMALL_STATE(12)] = 175,
  [SMALL_STATE(13)] = 193,
  [SMALL_STATE(14)] = 211,
  [SMALL_STATE(15)] = 236,
  [SMALL_STATE(16)] = 261,
  [SMALL_STATE(17)] = 282,
  [SMALL_STATE(18)] = 307,
  [SMALL_STATE(19)] = 324,
  [SMALL_STATE(20)] = 345,
  [SMALL_STATE(21)] = 366,
  [SMALL_STATE(22)] = 387,
  [SMALL_STATE(23)] = 404,
  [SMALL_STATE(24)] = 429,
  [SMALL_STATE(25)] = 446,
  [SMALL_STATE(26)] = 471,
  [SMALL_STATE(27)] = 496,
  [SMALL_STATE(28)] = 513,
  [SMALL_STATE(29)] = 530,
  [SMALL_STATE(30)] = 547,
  [SMALL_STATE(31)] = 564,
  [SMALL_STATE(32)] = 583,
  [SMALL_STATE(33)] = 600,
  [SMALL_STATE(34)] = 617,
  [SMALL_STATE(35)] = 638,
  [SMALL_STATE(36)] = 663,
  [SMALL_STATE(37)] = 680,
  [SMALL_STATE(38)] = 701,
  [SMALL_STATE(39)] = 710,
  [SMALL_STATE(40)] = 719,
  [SMALL_STATE(41)] = 723,
  [SMALL_STATE(42)] = 727,
  [SMALL_STATE(43)] = 731,
  [SMALL_STATE(44)] = 735,
  [SMALL_STATE(45)] = 739,
};

static const TSParseActionEntry ts_parse_actions[] = {
  [0] = {.entry = {.count = 0, .reusable = false}},
  [1] = {.entry = {.count = 1, .reusable = false}}, RECOVER(),
  [3] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 0, 0, 0),
  [5] = {.entry = {.count = 1, .reusable = true}}, SHIFT(3),
  [7] = {.entry = {.count = 1, .reusable = false}}, SHIFT(15),
  [9] = {.entry = {.count = 1, .reusable = true}}, SHIFT(35),
  [11] = {.entry = {.count = 1, .reusable = false}}, SHIFT(25),
  [13] = {.entry = {.count = 1, .reusable = false}}, SHIFT(45),
  [15] = {.entry = {.count = 1, .reusable = true}}, SHIFT(38),
  [17] = {.entry = {.count = 1, .reusable = true}}, SHIFT(13),
  [19] = {.entry = {.count = 1, .reusable = false}}, SHIFT(31),
  [21] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0),
  [23] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(3),
  [26] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(15),
  [29] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(35),
  [32] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(25),
  [35] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(45),
  [38] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(38),
  [41] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(13),
  [44] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(31),
  [47] = {.entry = {.count = 1, .reusable = true}}, SHIFT(18),
  [49] = {.entry = {.count = 1, .reusable = true}}, SHIFT(29),
  [51] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 1, 0, 0),
  [53] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_if_statement, 5, 0, 0),
  [55] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_if_statement, 5, 0, 0),
  [57] = {.entry = {.count = 1, .reusable = false}}, SHIFT(41),
  [59] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_binary_expression, 3, 0, 0),
  [61] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_binary_expression, 3, 0, 0),
  [63] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_unary_expression, 2, 0, 0),
  [65] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_unary_expression, 2, 0, 0),
  [67] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expression, 1, 0, 0),
  [69] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_expression, 1, 0, 0),
  [71] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_grouped_expression, 3, 0, 0),
  [73] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_grouped_expression, 3, 0, 0),
  [75] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_primary_expression, 1, 0, 0),
  [77] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_primary_expression, 1, 0, 0),
  [79] = {.entry = {.count = 1, .reusable = true}}, SHIFT(24),
  [81] = {.entry = {.count = 1, .reusable = true}}, SHIFT(39),
  [83] = {.entry = {.count = 1, .reusable = false}}, SHIFT(39),
  [85] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_block, 2, 0, 0),
  [87] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_block, 2, 0, 0),
  [89] = {.entry = {.count = 1, .reusable = true}}, SHIFT(7),
  [91] = {.entry = {.count = 1, .reusable = true}}, SHIFT(12),
  [93] = {.entry = {.count = 1, .reusable = true}}, SHIFT(32),
  [95] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_declaration, 1, 0, 0),
  [97] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_declaration, 1, 0, 0),
  [99] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expression_statement, 2, 0, 0),
  [101] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_expression_statement, 2, 0, 0),
  [103] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_variable_declaration, 5, 0, 0),
  [105] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_variable_declaration, 5, 0, 0),
  [107] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_statement, 1, 0, 0),
  [109] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_statement, 1, 0, 0),
  [111] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_block, 3, 0, 0),
  [113] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_block, 3, 0, 0),
  [115] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_else_statement, 4, 0, 0),
  [117] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_else_statement, 4, 0, 0),
  [119] = {.entry = {.count = 1, .reusable = false}}, SHIFT(23),
  [121] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_print_statement, 3, 0, 0),
  [123] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_print_statement, 3, 0, 0),
  [125] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_assignment_statement, 4, 0, 0),
  [127] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_assignment_statement, 4, 0, 0),
  [129] = {.entry = {.count = 1, .reusable = true}}, SHIFT(33),
  [131] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_if_statement, 6, 0, 0),
  [133] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_if_statement, 6, 0, 0),
  [135] = {.entry = {.count = 1, .reusable = true}}, SHIFT(27),
  [137] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_unary_operator, 1, 0, 0),
  [139] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_binary_operator, 1, 0, 0),
  [141] = {.entry = {.count = 1, .reusable = true}}, SHIFT(14),
  [143] = {.entry = {.count = 1, .reusable = true}}, SHIFT(6),
  [145] = {.entry = {.count = 1, .reusable = true}},  ACCEPT_INPUT(),
  [147] = {.entry = {.count = 1, .reusable = true}}, SHIFT(8),
  [149] = {.entry = {.count = 1, .reusable = true}}, SHIFT(30),
  [151] = {.entry = {.count = 1, .reusable = true}}, SHIFT(40),
};

#ifdef __cplusplus
extern "C" {
#endif
#ifdef TREE_SITTER_HIDE_SYMBOLS
#define TS_PUBLIC
#elif defined(_WIN32)
#define TS_PUBLIC __declspec(dllexport)
#else
#define TS_PUBLIC __attribute__((visibility("default")))
#endif

TS_PUBLIC const TSLanguage *tree_sitter_swlox(void) {
  static const TSLanguage language = {
    .version = LANGUAGE_VERSION,
    .symbol_count = SYMBOL_COUNT,
    .alias_count = ALIAS_COUNT,
    .token_count = TOKEN_COUNT,
    .external_token_count = EXTERNAL_TOKEN_COUNT,
    .state_count = STATE_COUNT,
    .large_state_count = LARGE_STATE_COUNT,
    .production_id_count = PRODUCTION_ID_COUNT,
    .field_count = FIELD_COUNT,
    .max_alias_sequence_length = MAX_ALIAS_SEQUENCE_LENGTH,
    .parse_table = &ts_parse_table[0][0],
    .small_parse_table = ts_small_parse_table,
    .small_parse_table_map = ts_small_parse_table_map,
    .parse_actions = ts_parse_actions,
    .symbol_names = ts_symbol_names,
    .symbol_metadata = ts_symbol_metadata,
    .public_symbol_map = ts_symbol_map,
    .alias_map = ts_non_terminal_alias_map,
    .alias_sequences = &ts_alias_sequences[0][0],
    .lex_modes = ts_lex_modes,
    .lex_fn = ts_lex,
    .primary_state_ids = ts_primary_state_ids,
  };
  return &language;
}
#ifdef __cplusplus
}
#endif
