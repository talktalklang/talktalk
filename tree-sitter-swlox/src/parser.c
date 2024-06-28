#include "tree_sitter/parser.h"

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#define LANGUAGE_VERSION 14
#define STATE_COUNT 32
#define LARGE_STATE_COUNT 4
#define SYMBOL_COUNT 36
#define ALIAS_COUNT 0
#define TOKEN_COUNT 21
#define EXTERNAL_TOKEN_COUNT 0
#define FIELD_COUNT 0
#define MAX_ALIAS_SEQUENCE_LENGTH 5
#define PRODUCTION_ID_COUNT 1

enum ts_symbol_identifiers {
  anon_sym_SEMI = 1,
  anon_sym_LPAREN = 2,
  anon_sym_RPAREN = 3,
  anon_sym_print = 4,
  anon_sym_EQ = 5,
  anon_sym_var = 6,
  anon_sym_DASH = 7,
  anon_sym_BANG = 8,
  anon_sym_PLUS = 9,
  anon_sym_STAR = 10,
  anon_sym_SLASH = 11,
  anon_sym_EQ_EQ = 12,
  anon_sym_BANG_EQ = 13,
  anon_sym_LT = 14,
  anon_sym_LT_EQ = 15,
  anon_sym_GT = 16,
  anon_sym_GT_EQ = 17,
  sym_number_literal = 18,
  sym_string_literal = 19,
  sym_variable = 20,
  sym_source_file = 21,
  sym_declaration = 22,
  sym_statement = 23,
  sym_expression_statement = 24,
  sym_expression = 25,
  sym_grouped_expression = 26,
  sym_binary_expression = 27,
  sym_print_statement = 28,
  sym_assignment_statement = 29,
  sym_unary_expression = 30,
  sym_primary_expression = 31,
  sym_variable_declaration = 32,
  sym_unary_operator = 33,
  sym_binary_operator = 34,
  aux_sym_source_file_repeat1 = 35,
};

static const char * const ts_symbol_names[] = {
  [ts_builtin_sym_end] = "end",
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
  [sym_number_literal] = "number_literal",
  [sym_string_literal] = "string_literal",
  [sym_variable] = "variable",
  [sym_source_file] = "source_file",
  [sym_declaration] = "declaration",
  [sym_statement] = "statement",
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
  [sym_number_literal] = sym_number_literal,
  [sym_string_literal] = sym_string_literal,
  [sym_variable] = sym_variable,
  [sym_source_file] = sym_source_file,
  [sym_declaration] = sym_declaration,
  [sym_statement] = sym_statement,
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
  [sym_statement] = {
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
};

static bool ts_lex(TSLexer *lexer, TSStateId state) {
  START_LEXER();
  eof = lexer->eof(lexer);
  switch (state) {
    case 0:
      if (eof) ADVANCE(7);
      ADVANCE_MAP(
        '!', 16,
        '"', 3,
        '(', 9,
        ')', 10,
        '*', 18,
        '+', 17,
        '-', 14,
        '/', 19,
        ';', 8,
        '<', 22,
        '=', 12,
        '>', 24,
        'p', 32,
        'v', 29,
      );
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(0);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(26);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    case 1:
      if (lookahead == '!') ADVANCE(15);
      if (lookahead == '"') ADVANCE(3);
      if (lookahead == '(') ADVANCE(9);
      if (lookahead == '-') ADVANCE(14);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(1);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(26);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    case 2:
      ADVANCE_MAP(
        '!', 4,
        ')', 10,
        '*', 18,
        '+', 17,
        '-', 14,
        '/', 19,
        ';', 8,
        '<', 22,
        '=', 12,
        '>', 24,
      );
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(2);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    case 3:
      if (lookahead == '"') ADVANCE(28);
      if (lookahead != 0) ADVANCE(3);
      END_STATE();
    case 4:
      if (lookahead == '=') ADVANCE(21);
      END_STATE();
    case 5:
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(27);
      END_STATE();
    case 6:
      if (eof) ADVANCE(7);
      if (lookahead == '!') ADVANCE(15);
      if (lookahead == '"') ADVANCE(3);
      if (lookahead == '(') ADVANCE(9);
      if (lookahead == '-') ADVANCE(14);
      if (lookahead == 'p') ADVANCE(32);
      if (lookahead == 'v') ADVANCE(29);
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(6);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(26);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    case 7:
      ACCEPT_TOKEN(ts_builtin_sym_end);
      END_STATE();
    case 8:
      ACCEPT_TOKEN(anon_sym_SEMI);
      END_STATE();
    case 9:
      ACCEPT_TOKEN(anon_sym_LPAREN);
      END_STATE();
    case 10:
      ACCEPT_TOKEN(anon_sym_RPAREN);
      END_STATE();
    case 11:
      ACCEPT_TOKEN(anon_sym_print);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    case 12:
      ACCEPT_TOKEN(anon_sym_EQ);
      if (lookahead == '=') ADVANCE(20);
      END_STATE();
    case 13:
      ACCEPT_TOKEN(anon_sym_var);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    case 14:
      ACCEPT_TOKEN(anon_sym_DASH);
      END_STATE();
    case 15:
      ACCEPT_TOKEN(anon_sym_BANG);
      END_STATE();
    case 16:
      ACCEPT_TOKEN(anon_sym_BANG);
      if (lookahead == '=') ADVANCE(21);
      END_STATE();
    case 17:
      ACCEPT_TOKEN(anon_sym_PLUS);
      END_STATE();
    case 18:
      ACCEPT_TOKEN(anon_sym_STAR);
      END_STATE();
    case 19:
      ACCEPT_TOKEN(anon_sym_SLASH);
      END_STATE();
    case 20:
      ACCEPT_TOKEN(anon_sym_EQ_EQ);
      END_STATE();
    case 21:
      ACCEPT_TOKEN(anon_sym_BANG_EQ);
      END_STATE();
    case 22:
      ACCEPT_TOKEN(anon_sym_LT);
      if (lookahead == '=') ADVANCE(23);
      END_STATE();
    case 23:
      ACCEPT_TOKEN(anon_sym_LT_EQ);
      END_STATE();
    case 24:
      ACCEPT_TOKEN(anon_sym_GT);
      if (lookahead == '=') ADVANCE(25);
      END_STATE();
    case 25:
      ACCEPT_TOKEN(anon_sym_GT_EQ);
      END_STATE();
    case 26:
      ACCEPT_TOKEN(sym_number_literal);
      if (lookahead == '.') ADVANCE(5);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(26);
      END_STATE();
    case 27:
      ACCEPT_TOKEN(sym_number_literal);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(27);
      END_STATE();
    case 28:
      ACCEPT_TOKEN(sym_string_literal);
      END_STATE();
    case 29:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'a') ADVANCE(33);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('b' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    case 30:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'i') ADVANCE(31);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    case 31:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'n') ADVANCE(34);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    case 32:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'r') ADVANCE(30);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    case 33:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'r') ADVANCE(13);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    case 34:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 't') ADVANCE(11);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    case 35:
      ACCEPT_TOKEN(sym_variable);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(35);
      END_STATE();
    default:
      return false;
  }
}

static const TSLexMode ts_lex_modes[STATE_COUNT] = {
  [0] = {.lex_state = 0},
  [1] = {.lex_state = 6},
  [2] = {.lex_state = 6},
  [3] = {.lex_state = 6},
  [4] = {.lex_state = 2},
  [5] = {.lex_state = 2},
  [6] = {.lex_state = 2},
  [7] = {.lex_state = 1},
  [8] = {.lex_state = 2},
  [9] = {.lex_state = 2},
  [10] = {.lex_state = 1},
  [11] = {.lex_state = 2},
  [12] = {.lex_state = 2},
  [13] = {.lex_state = 2},
  [14] = {.lex_state = 1},
  [15] = {.lex_state = 2},
  [16] = {.lex_state = 2},
  [17] = {.lex_state = 1},
  [18] = {.lex_state = 1},
  [19] = {.lex_state = 2},
  [20] = {.lex_state = 1},
  [21] = {.lex_state = 6},
  [22] = {.lex_state = 6},
  [23] = {.lex_state = 6},
  [24] = {.lex_state = 6},
  [25] = {.lex_state = 6},
  [26] = {.lex_state = 6},
  [27] = {.lex_state = 1},
  [28] = {.lex_state = 1},
  [29] = {.lex_state = 2},
  [30] = {.lex_state = 0},
  [31] = {.lex_state = 0},
};

static const uint16_t ts_parse_table[LARGE_STATE_COUNT][SYMBOL_COUNT] = {
  [0] = {
    [ts_builtin_sym_end] = ACTIONS(1),
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
    [sym_number_literal] = ACTIONS(1),
    [sym_string_literal] = ACTIONS(1),
    [sym_variable] = ACTIONS(1),
  },
  [1] = {
    [sym_source_file] = STATE(30),
    [sym_declaration] = STATE(2),
    [sym_statement] = STATE(24),
    [sym_expression_statement] = STATE(23),
    [sym_expression] = STATE(12),
    [sym_grouped_expression] = STATE(13),
    [sym_binary_expression] = STATE(13),
    [sym_print_statement] = STATE(23),
    [sym_assignment_statement] = STATE(23),
    [sym_unary_expression] = STATE(13),
    [sym_primary_expression] = STATE(13),
    [sym_variable_declaration] = STATE(24),
    [sym_unary_operator] = STATE(14),
    [aux_sym_source_file_repeat1] = STATE(2),
    [ts_builtin_sym_end] = ACTIONS(3),
    [anon_sym_LPAREN] = ACTIONS(5),
    [anon_sym_print] = ACTIONS(7),
    [anon_sym_var] = ACTIONS(9),
    [anon_sym_DASH] = ACTIONS(11),
    [anon_sym_BANG] = ACTIONS(11),
    [sym_number_literal] = ACTIONS(13),
    [sym_string_literal] = ACTIONS(13),
    [sym_variable] = ACTIONS(15),
  },
  [2] = {
    [sym_declaration] = STATE(3),
    [sym_statement] = STATE(24),
    [sym_expression_statement] = STATE(23),
    [sym_expression] = STATE(12),
    [sym_grouped_expression] = STATE(13),
    [sym_binary_expression] = STATE(13),
    [sym_print_statement] = STATE(23),
    [sym_assignment_statement] = STATE(23),
    [sym_unary_expression] = STATE(13),
    [sym_primary_expression] = STATE(13),
    [sym_variable_declaration] = STATE(24),
    [sym_unary_operator] = STATE(14),
    [aux_sym_source_file_repeat1] = STATE(3),
    [ts_builtin_sym_end] = ACTIONS(17),
    [anon_sym_LPAREN] = ACTIONS(5),
    [anon_sym_print] = ACTIONS(7),
    [anon_sym_var] = ACTIONS(9),
    [anon_sym_DASH] = ACTIONS(11),
    [anon_sym_BANG] = ACTIONS(11),
    [sym_number_literal] = ACTIONS(13),
    [sym_string_literal] = ACTIONS(13),
    [sym_variable] = ACTIONS(15),
  },
  [3] = {
    [sym_declaration] = STATE(3),
    [sym_statement] = STATE(24),
    [sym_expression_statement] = STATE(23),
    [sym_expression] = STATE(12),
    [sym_grouped_expression] = STATE(13),
    [sym_binary_expression] = STATE(13),
    [sym_print_statement] = STATE(23),
    [sym_assignment_statement] = STATE(23),
    [sym_unary_expression] = STATE(13),
    [sym_primary_expression] = STATE(13),
    [sym_variable_declaration] = STATE(24),
    [sym_unary_operator] = STATE(14),
    [aux_sym_source_file_repeat1] = STATE(3),
    [ts_builtin_sym_end] = ACTIONS(19),
    [anon_sym_LPAREN] = ACTIONS(21),
    [anon_sym_print] = ACTIONS(24),
    [anon_sym_var] = ACTIONS(27),
    [anon_sym_DASH] = ACTIONS(30),
    [anon_sym_BANG] = ACTIONS(30),
    [sym_number_literal] = ACTIONS(33),
    [sym_string_literal] = ACTIONS(33),
    [sym_variable] = ACTIONS(36),
  },
};

static const uint16_t ts_small_parse_table[] = {
  [0] = 3,
    STATE(20), 1,
      sym_binary_operator,
    ACTIONS(41), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(39), 10,
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
  [20] = 3,
    STATE(20), 1,
      sym_binary_operator,
    ACTIONS(45), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(43), 10,
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
  [40] = 2,
    ACTIONS(49), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(47), 10,
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
  [57] = 6,
    ACTIONS(5), 1,
      anon_sym_LPAREN,
    STATE(14), 1,
      sym_unary_operator,
    STATE(15), 1,
      sym_expression,
    ACTIONS(11), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(13), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(13), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [82] = 3,
    ACTIONS(53), 1,
      anon_sym_EQ,
    ACTIONS(55), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(51), 9,
      anon_sym_SEMI,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [101] = 4,
    ACTIONS(57), 1,
      anon_sym_SEMI,
    STATE(20), 1,
      sym_binary_operator,
    ACTIONS(61), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(59), 8,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [122] = 6,
    ACTIONS(5), 1,
      anon_sym_LPAREN,
    STATE(14), 1,
      sym_unary_operator,
    STATE(16), 1,
      sym_expression,
    ACTIONS(11), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(13), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(13), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [147] = 4,
    ACTIONS(63), 1,
      anon_sym_SEMI,
    STATE(20), 1,
      sym_binary_operator,
    ACTIONS(61), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(59), 8,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [168] = 4,
    ACTIONS(65), 1,
      anon_sym_SEMI,
    STATE(20), 1,
      sym_binary_operator,
    ACTIONS(61), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(59), 8,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [189] = 2,
    ACTIONS(69), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(67), 10,
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
  [206] = 6,
    ACTIONS(5), 1,
      anon_sym_LPAREN,
    STATE(5), 1,
      sym_expression,
    STATE(14), 1,
      sym_unary_operator,
    ACTIONS(11), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(13), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(13), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [231] = 4,
    ACTIONS(71), 1,
      anon_sym_RPAREN,
    STATE(20), 1,
      sym_binary_operator,
    ACTIONS(61), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(59), 8,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [252] = 4,
    ACTIONS(73), 1,
      anon_sym_SEMI,
    STATE(20), 1,
      sym_binary_operator,
    ACTIONS(61), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(59), 8,
      anon_sym_DASH,
      anon_sym_PLUS,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_LT_EQ,
      anon_sym_GT_EQ,
  [273] = 6,
    ACTIONS(5), 1,
      anon_sym_LPAREN,
    STATE(9), 1,
      sym_expression,
    STATE(14), 1,
      sym_unary_operator,
    ACTIONS(11), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(13), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(13), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [298] = 6,
    ACTIONS(5), 1,
      anon_sym_LPAREN,
    STATE(11), 1,
      sym_expression,
    STATE(14), 1,
      sym_unary_operator,
    ACTIONS(11), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(13), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(13), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [323] = 2,
    ACTIONS(55), 2,
      anon_sym_LT,
      anon_sym_GT,
    ACTIONS(51), 10,
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
  [340] = 6,
    ACTIONS(5), 1,
      anon_sym_LPAREN,
    STATE(4), 1,
      sym_expression,
    STATE(14), 1,
      sym_unary_operator,
    ACTIONS(11), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(13), 3,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
    STATE(13), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [365] = 2,
    ACTIONS(77), 3,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(75), 6,
      ts_builtin_sym_end,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [379] = 2,
    ACTIONS(81), 3,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(79), 6,
      ts_builtin_sym_end,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [393] = 2,
    ACTIONS(85), 3,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(83), 6,
      ts_builtin_sym_end,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [407] = 2,
    ACTIONS(89), 3,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(87), 6,
      ts_builtin_sym_end,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [421] = 2,
    ACTIONS(93), 3,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(91), 6,
      ts_builtin_sym_end,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [435] = 2,
    ACTIONS(97), 3,
      anon_sym_print,
      anon_sym_var,
      sym_variable,
    ACTIONS(95), 6,
      ts_builtin_sym_end,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [449] = 1,
    ACTIONS(99), 6,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
  [458] = 1,
    ACTIONS(101), 6,
      anon_sym_LPAREN,
      anon_sym_DASH,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
      sym_variable,
  [467] = 1,
    ACTIONS(103), 1,
      sym_variable,
  [471] = 1,
    ACTIONS(105), 1,
      ts_builtin_sym_end,
  [475] = 1,
    ACTIONS(107), 1,
      anon_sym_EQ,
};

static const uint32_t ts_small_parse_table_map[] = {
  [SMALL_STATE(4)] = 0,
  [SMALL_STATE(5)] = 20,
  [SMALL_STATE(6)] = 40,
  [SMALL_STATE(7)] = 57,
  [SMALL_STATE(8)] = 82,
  [SMALL_STATE(9)] = 101,
  [SMALL_STATE(10)] = 122,
  [SMALL_STATE(11)] = 147,
  [SMALL_STATE(12)] = 168,
  [SMALL_STATE(13)] = 189,
  [SMALL_STATE(14)] = 206,
  [SMALL_STATE(15)] = 231,
  [SMALL_STATE(16)] = 252,
  [SMALL_STATE(17)] = 273,
  [SMALL_STATE(18)] = 298,
  [SMALL_STATE(19)] = 323,
  [SMALL_STATE(20)] = 340,
  [SMALL_STATE(21)] = 365,
  [SMALL_STATE(22)] = 379,
  [SMALL_STATE(23)] = 393,
  [SMALL_STATE(24)] = 407,
  [SMALL_STATE(25)] = 421,
  [SMALL_STATE(26)] = 435,
  [SMALL_STATE(27)] = 449,
  [SMALL_STATE(28)] = 458,
  [SMALL_STATE(29)] = 467,
  [SMALL_STATE(30)] = 471,
  [SMALL_STATE(31)] = 475,
};

static const TSParseActionEntry ts_parse_actions[] = {
  [0] = {.entry = {.count = 0, .reusable = false}},
  [1] = {.entry = {.count = 1, .reusable = false}}, RECOVER(),
  [3] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 0, 0, 0),
  [5] = {.entry = {.count = 1, .reusable = true}}, SHIFT(7),
  [7] = {.entry = {.count = 1, .reusable = false}}, SHIFT(10),
  [9] = {.entry = {.count = 1, .reusable = false}}, SHIFT(29),
  [11] = {.entry = {.count = 1, .reusable = true}}, SHIFT(28),
  [13] = {.entry = {.count = 1, .reusable = true}}, SHIFT(19),
  [15] = {.entry = {.count = 1, .reusable = false}}, SHIFT(8),
  [17] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 1, 0, 0),
  [19] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0),
  [21] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(7),
  [24] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(10),
  [27] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(29),
  [30] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(28),
  [33] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(19),
  [36] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(8),
  [39] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_binary_expression, 3, 0, 0),
  [41] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_binary_expression, 3, 0, 0),
  [43] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_unary_expression, 2, 0, 0),
  [45] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_unary_expression, 2, 0, 0),
  [47] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_grouped_expression, 3, 0, 0),
  [49] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_grouped_expression, 3, 0, 0),
  [51] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_primary_expression, 1, 0, 0),
  [53] = {.entry = {.count = 1, .reusable = false}}, SHIFT(18),
  [55] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_primary_expression, 1, 0, 0),
  [57] = {.entry = {.count = 1, .reusable = true}}, SHIFT(26),
  [59] = {.entry = {.count = 1, .reusable = true}}, SHIFT(27),
  [61] = {.entry = {.count = 1, .reusable = false}}, SHIFT(27),
  [63] = {.entry = {.count = 1, .reusable = true}}, SHIFT(25),
  [65] = {.entry = {.count = 1, .reusable = true}}, SHIFT(21),
  [67] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expression, 1, 0, 0),
  [69] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_expression, 1, 0, 0),
  [71] = {.entry = {.count = 1, .reusable = true}}, SHIFT(6),
  [73] = {.entry = {.count = 1, .reusable = true}}, SHIFT(22),
  [75] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expression_statement, 2, 0, 0),
  [77] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_expression_statement, 2, 0, 0),
  [79] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_print_statement, 3, 0, 0),
  [81] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_print_statement, 3, 0, 0),
  [83] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_statement, 1, 0, 0),
  [85] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_statement, 1, 0, 0),
  [87] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_declaration, 1, 0, 0),
  [89] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_declaration, 1, 0, 0),
  [91] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_assignment_statement, 4, 0, 0),
  [93] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_assignment_statement, 4, 0, 0),
  [95] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_variable_declaration, 5, 0, 0),
  [97] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_variable_declaration, 5, 0, 0),
  [99] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_binary_operator, 1, 0, 0),
  [101] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_unary_operator, 1, 0, 0),
  [103] = {.entry = {.count = 1, .reusable = true}}, SHIFT(31),
  [105] = {.entry = {.count = 1, .reusable = true}},  ACCEPT_INPUT(),
  [107] = {.entry = {.count = 1, .reusable = true}}, SHIFT(17),
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
