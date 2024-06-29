#include "tree_sitter/parser.h"

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#define LANGUAGE_VERSION 14
#define STATE_COUNT 61
#define LARGE_STATE_COUNT 8
#define SYMBOL_COUNT 55
#define ALIAS_COUNT 0
#define TOKEN_COUNT 32
#define EXTERNAL_TOKEN_COUNT 0
#define FIELD_COUNT 0
#define MAX_ALIAS_SEQUENCE_LENGTH 5
#define PRODUCTION_ID_COUNT 1

enum ts_symbol_identifiers {
  anon_sym_LBRACE = 1,
  anon_sym_RBRACE = 2,
  anon_sym_if = 3,
  anon_sym_else = 4,
  anon_sym_EQ_EQ = 5,
  anon_sym_BANG_EQ = 6,
  anon_sym_GT = 7,
  anon_sym_GT_EQ = 8,
  anon_sym_LT = 9,
  anon_sym_LT_EQ = 10,
  anon_sym_PLUS = 11,
  anon_sym_DASH = 12,
  anon_sym_STAR = 13,
  anon_sym_SLASH = 14,
  anon_sym_PIPE_PIPE = 15,
  anon_sym_AMP_AMP = 16,
  anon_sym_while = 17,
  anon_sym_SEMI = 18,
  anon_sym_LPAREN = 19,
  anon_sym_RPAREN = 20,
  anon_sym_print = 21,
  anon_sym_EQ = 22,
  anon_sym_BANG = 23,
  anon_sym_nil = 24,
  anon_sym_var = 25,
  anon_sym_COMMA = 26,
  anon_sym_true = 27,
  anon_sym_false = 28,
  sym_number_literal = 29,
  sym_string_literal = 30,
  sym_variable = 31,
  sym_source_file = 32,
  sym_declaration = 33,
  sym_block = 34,
  sym_statement = 35,
  sym_if_statement = 36,
  sym_else_statement = 37,
  sym_while_statement = 38,
  sym_expression_statement = 39,
  sym_expression = 40,
  sym_grouped_expression = 41,
  sym_binary_expression = 42,
  sym_print_statement = 43,
  sym_assignment_statement = 44,
  sym_unary_expression = 45,
  sym_primary_expression = 46,
  sym_variable_declaration = 47,
  sym_call = 48,
  sym_arguments = 49,
  sym_binary_operator = 50,
  sym_boolean_literal = 51,
  aux_sym_source_file_repeat1 = 52,
  aux_sym_call_repeat1 = 53,
  aux_sym_arguments_repeat1 = 54,
};

static const char * const ts_symbol_names[] = {
  [ts_builtin_sym_end] = "end",
  [anon_sym_LBRACE] = "{",
  [anon_sym_RBRACE] = "}",
  [anon_sym_if] = "if",
  [anon_sym_else] = "else",
  [anon_sym_EQ_EQ] = "==",
  [anon_sym_BANG_EQ] = "!=",
  [anon_sym_GT] = ">",
  [anon_sym_GT_EQ] = ">=",
  [anon_sym_LT] = "<",
  [anon_sym_LT_EQ] = "<=",
  [anon_sym_PLUS] = "+",
  [anon_sym_DASH] = "-",
  [anon_sym_STAR] = "*",
  [anon_sym_SLASH] = "/",
  [anon_sym_PIPE_PIPE] = "||",
  [anon_sym_AMP_AMP] = "&&",
  [anon_sym_while] = "while",
  [anon_sym_SEMI] = ";",
  [anon_sym_LPAREN] = "(",
  [anon_sym_RPAREN] = ")",
  [anon_sym_print] = "print",
  [anon_sym_EQ] = "=",
  [anon_sym_BANG] = "!",
  [anon_sym_nil] = "nil",
  [anon_sym_var] = "var",
  [anon_sym_COMMA] = ",",
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
  [sym_while_statement] = "while_statement",
  [sym_expression_statement] = "expression_statement",
  [sym_expression] = "expression",
  [sym_grouped_expression] = "grouped_expression",
  [sym_binary_expression] = "binary_expression",
  [sym_print_statement] = "print_statement",
  [sym_assignment_statement] = "assignment_statement",
  [sym_unary_expression] = "unary_expression",
  [sym_primary_expression] = "primary_expression",
  [sym_variable_declaration] = "variable_declaration",
  [sym_call] = "call",
  [sym_arguments] = "arguments",
  [sym_binary_operator] = "binary_operator",
  [sym_boolean_literal] = "boolean_literal",
  [aux_sym_source_file_repeat1] = "source_file_repeat1",
  [aux_sym_call_repeat1] = "call_repeat1",
  [aux_sym_arguments_repeat1] = "arguments_repeat1",
};

static const TSSymbol ts_symbol_map[] = {
  [ts_builtin_sym_end] = ts_builtin_sym_end,
  [anon_sym_LBRACE] = anon_sym_LBRACE,
  [anon_sym_RBRACE] = anon_sym_RBRACE,
  [anon_sym_if] = anon_sym_if,
  [anon_sym_else] = anon_sym_else,
  [anon_sym_EQ_EQ] = anon_sym_EQ_EQ,
  [anon_sym_BANG_EQ] = anon_sym_BANG_EQ,
  [anon_sym_GT] = anon_sym_GT,
  [anon_sym_GT_EQ] = anon_sym_GT_EQ,
  [anon_sym_LT] = anon_sym_LT,
  [anon_sym_LT_EQ] = anon_sym_LT_EQ,
  [anon_sym_PLUS] = anon_sym_PLUS,
  [anon_sym_DASH] = anon_sym_DASH,
  [anon_sym_STAR] = anon_sym_STAR,
  [anon_sym_SLASH] = anon_sym_SLASH,
  [anon_sym_PIPE_PIPE] = anon_sym_PIPE_PIPE,
  [anon_sym_AMP_AMP] = anon_sym_AMP_AMP,
  [anon_sym_while] = anon_sym_while,
  [anon_sym_SEMI] = anon_sym_SEMI,
  [anon_sym_LPAREN] = anon_sym_LPAREN,
  [anon_sym_RPAREN] = anon_sym_RPAREN,
  [anon_sym_print] = anon_sym_print,
  [anon_sym_EQ] = anon_sym_EQ,
  [anon_sym_BANG] = anon_sym_BANG,
  [anon_sym_nil] = anon_sym_nil,
  [anon_sym_var] = anon_sym_var,
  [anon_sym_COMMA] = anon_sym_COMMA,
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
  [sym_while_statement] = sym_while_statement,
  [sym_expression_statement] = sym_expression_statement,
  [sym_expression] = sym_expression,
  [sym_grouped_expression] = sym_grouped_expression,
  [sym_binary_expression] = sym_binary_expression,
  [sym_print_statement] = sym_print_statement,
  [sym_assignment_statement] = sym_assignment_statement,
  [sym_unary_expression] = sym_unary_expression,
  [sym_primary_expression] = sym_primary_expression,
  [sym_variable_declaration] = sym_variable_declaration,
  [sym_call] = sym_call,
  [sym_arguments] = sym_arguments,
  [sym_binary_operator] = sym_binary_operator,
  [sym_boolean_literal] = sym_boolean_literal,
  [aux_sym_source_file_repeat1] = aux_sym_source_file_repeat1,
  [aux_sym_call_repeat1] = aux_sym_call_repeat1,
  [aux_sym_arguments_repeat1] = aux_sym_arguments_repeat1,
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
  [anon_sym_EQ_EQ] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_BANG_EQ] = {
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
  [anon_sym_LT] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_LT_EQ] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_PLUS] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_DASH] = {
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
  [anon_sym_PIPE_PIPE] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_AMP_AMP] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_while] = {
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
  [anon_sym_BANG] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_nil] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_var] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_COMMA] = {
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
  [sym_while_statement] = {
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
  [sym_call] = {
    .visible = true,
    .named = true,
  },
  [sym_arguments] = {
    .visible = true,
    .named = true,
  },
  [sym_binary_operator] = {
    .visible = true,
    .named = true,
  },
  [sym_boolean_literal] = {
    .visible = true,
    .named = true,
  },
  [aux_sym_source_file_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_call_repeat1] = {
    .visible = false,
    .named = false,
  },
  [aux_sym_arguments_repeat1] = {
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
  [5] = 4,
  [6] = 6,
  [7] = 3,
  [8] = 8,
  [9] = 9,
  [10] = 10,
  [11] = 11,
  [12] = 9,
  [13] = 13,
  [14] = 14,
  [15] = 15,
  [16] = 16,
  [17] = 17,
  [18] = 18,
  [19] = 19,
  [20] = 11,
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
  [46] = 46,
  [47] = 47,
  [48] = 48,
  [49] = 49,
  [50] = 50,
  [51] = 51,
  [52] = 52,
  [53] = 53,
  [54] = 54,
  [55] = 55,
  [56] = 56,
  [57] = 57,
  [58] = 58,
  [59] = 59,
  [60] = 60,
};

static bool ts_lex(TSLexer *lexer, TSStateId state) {
  START_LEXER();
  eof = lexer->eof(lexer);
  switch (state) {
    case 0:
      if (eof) ADVANCE(10);
      ADVANCE_MAP(
        '!', 34,
        '"', 3,
        '&', 4,
        '(', 29,
        ')', 30,
        '*', 23,
        '+', 21,
        ',', 37,
        '-', 22,
        '/', 24,
        ';', 28,
        '<', 19,
        '=', 32,
        '>', 17,
        'e', 54,
        'f', 44,
        'i', 49,
        'n', 52,
        'p', 61,
        't', 59,
        'v', 43,
        'w', 50,
        '{', 11,
        '|', 6,
        '}', 12,
      );
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(0);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(40);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 1:
      ADVANCE_MAP(
        '!', 33,
        '"', 3,
        '(', 29,
        ')', 30,
        '-', 22,
        'f', 44,
        'n', 52,
        't', 59,
      );
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(1);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(40);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 2:
      ADVANCE_MAP(
        '!', 5,
        '(', 29,
        ')', 30,
        '*', 23,
        '+', 21,
        ',', 37,
        '-', 22,
        '/', 24,
        ';', 28,
        '<', 19,
        '=', 32,
        '>', 17,
        '{', 11,
      );
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(2);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 3:
      if (lookahead == '"') ADVANCE(42);
      if (lookahead != 0) ADVANCE(3);
      END_STATE();
    case 4:
      if (lookahead == '&') ADVANCE(26);
      END_STATE();
    case 5:
      if (lookahead == '=') ADVANCE(16);
      END_STATE();
    case 6:
      if (lookahead == '|') ADVANCE(25);
      END_STATE();
    case 7:
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(41);
      END_STATE();
    case 8:
      if (eof) ADVANCE(10);
      ADVANCE_MAP(
        '!', 33,
        '"', 3,
        '(', 29,
        '-', 22,
        'e', 54,
        'f', 44,
        'i', 49,
        'n', 52,
        'p', 61,
        't', 59,
        'v', 43,
        'w', 50,
        '{', 11,
        '}', 12,
      );
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(8);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(40);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 9:
      if (eof) ADVANCE(10);
      ADVANCE_MAP(
        '!', 33,
        '"', 3,
        '(', 29,
        '-', 22,
        'f', 44,
        'i', 49,
        'n', 52,
        'p', 61,
        't', 59,
        'v', 43,
        'w', 50,
        '{', 11,
        '}', 12,
      );
      if (('\t' <= lookahead && lookahead <= '\r') ||
          lookahead == ' ') SKIP(9);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(40);
      if (('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 10:
      ACCEPT_TOKEN(ts_builtin_sym_end);
      END_STATE();
    case 11:
      ACCEPT_TOKEN(anon_sym_LBRACE);
      END_STATE();
    case 12:
      ACCEPT_TOKEN(anon_sym_RBRACE);
      END_STATE();
    case 13:
      ACCEPT_TOKEN(anon_sym_if);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 14:
      ACCEPT_TOKEN(anon_sym_else);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 15:
      ACCEPT_TOKEN(anon_sym_EQ_EQ);
      END_STATE();
    case 16:
      ACCEPT_TOKEN(anon_sym_BANG_EQ);
      END_STATE();
    case 17:
      ACCEPT_TOKEN(anon_sym_GT);
      if (lookahead == '=') ADVANCE(18);
      END_STATE();
    case 18:
      ACCEPT_TOKEN(anon_sym_GT_EQ);
      END_STATE();
    case 19:
      ACCEPT_TOKEN(anon_sym_LT);
      if (lookahead == '=') ADVANCE(20);
      END_STATE();
    case 20:
      ACCEPT_TOKEN(anon_sym_LT_EQ);
      END_STATE();
    case 21:
      ACCEPT_TOKEN(anon_sym_PLUS);
      END_STATE();
    case 22:
      ACCEPT_TOKEN(anon_sym_DASH);
      END_STATE();
    case 23:
      ACCEPT_TOKEN(anon_sym_STAR);
      END_STATE();
    case 24:
      ACCEPT_TOKEN(anon_sym_SLASH);
      END_STATE();
    case 25:
      ACCEPT_TOKEN(anon_sym_PIPE_PIPE);
      END_STATE();
    case 26:
      ACCEPT_TOKEN(anon_sym_AMP_AMP);
      END_STATE();
    case 27:
      ACCEPT_TOKEN(anon_sym_while);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 28:
      ACCEPT_TOKEN(anon_sym_SEMI);
      END_STATE();
    case 29:
      ACCEPT_TOKEN(anon_sym_LPAREN);
      END_STATE();
    case 30:
      ACCEPT_TOKEN(anon_sym_RPAREN);
      END_STATE();
    case 31:
      ACCEPT_TOKEN(anon_sym_print);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 32:
      ACCEPT_TOKEN(anon_sym_EQ);
      if (lookahead == '=') ADVANCE(15);
      END_STATE();
    case 33:
      ACCEPT_TOKEN(anon_sym_BANG);
      END_STATE();
    case 34:
      ACCEPT_TOKEN(anon_sym_BANG);
      if (lookahead == '=') ADVANCE(16);
      END_STATE();
    case 35:
      ACCEPT_TOKEN(anon_sym_nil);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 36:
      ACCEPT_TOKEN(anon_sym_var);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 37:
      ACCEPT_TOKEN(anon_sym_COMMA);
      END_STATE();
    case 38:
      ACCEPT_TOKEN(anon_sym_true);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 39:
      ACCEPT_TOKEN(anon_sym_false);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 40:
      ACCEPT_TOKEN(sym_number_literal);
      if (lookahead == '.') ADVANCE(7);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(40);
      END_STATE();
    case 41:
      ACCEPT_TOKEN(sym_number_literal);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(41);
      END_STATE();
    case 42:
      ACCEPT_TOKEN(sym_string_literal);
      END_STATE();
    case 43:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'a') ADVANCE(60);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('b' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 44:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'a') ADVANCE(57);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('b' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 45:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'e') ADVANCE(14);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 46:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'e') ADVANCE(38);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 47:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'e') ADVANCE(39);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 48:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'e') ADVANCE(27);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 49:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'f') ADVANCE(13);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 50:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'h') ADVANCE(53);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 51:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'i') ADVANCE(58);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 52:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'i') ADVANCE(55);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 53:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'i') ADVANCE(56);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 54:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'l') ADVANCE(62);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 55:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'l') ADVANCE(35);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 56:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'l') ADVANCE(48);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 57:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'l') ADVANCE(63);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 58:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'n') ADVANCE(64);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 59:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'r') ADVANCE(65);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 60:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'r') ADVANCE(36);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 61:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'r') ADVANCE(51);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 62:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 's') ADVANCE(45);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 63:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 's') ADVANCE(47);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 64:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 't') ADVANCE(31);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 65:
      ACCEPT_TOKEN(sym_variable);
      if (lookahead == 'u') ADVANCE(46);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    case 66:
      ACCEPT_TOKEN(sym_variable);
      if (('0' <= lookahead && lookahead <= '9') ||
          ('A' <= lookahead && lookahead <= 'Z') ||
          lookahead == '_' ||
          ('a' <= lookahead && lookahead <= 'z')) ADVANCE(66);
      END_STATE();
    default:
      return false;
  }
}

static const TSLexMode ts_lex_modes[STATE_COUNT] = {
  [0] = {.lex_state = 0},
  [1] = {.lex_state = 9},
  [2] = {.lex_state = 9},
  [3] = {.lex_state = 9},
  [4] = {.lex_state = 9},
  [5] = {.lex_state = 9},
  [6] = {.lex_state = 9},
  [7] = {.lex_state = 9},
  [8] = {.lex_state = 8},
  [9] = {.lex_state = 8},
  [10] = {.lex_state = 1},
  [11] = {.lex_state = 8},
  [12] = {.lex_state = 9},
  [13] = {.lex_state = 9},
  [14] = {.lex_state = 9},
  [15] = {.lex_state = 9},
  [16] = {.lex_state = 9},
  [17] = {.lex_state = 9},
  [18] = {.lex_state = 9},
  [19] = {.lex_state = 2},
  [20] = {.lex_state = 9},
  [21] = {.lex_state = 9},
  [22] = {.lex_state = 9},
  [23] = {.lex_state = 9},
  [24] = {.lex_state = 2},
  [25] = {.lex_state = 2},
  [26] = {.lex_state = 2},
  [27] = {.lex_state = 1},
  [28] = {.lex_state = 2},
  [29] = {.lex_state = 2},
  [30] = {.lex_state = 1},
  [31] = {.lex_state = 1},
  [32] = {.lex_state = 1},
  [33] = {.lex_state = 1},
  [34] = {.lex_state = 1},
  [35] = {.lex_state = 2},
  [36] = {.lex_state = 1},
  [37] = {.lex_state = 1},
  [38] = {.lex_state = 2},
  [39] = {.lex_state = 2},
  [40] = {.lex_state = 2},
  [41] = {.lex_state = 2},
  [42] = {.lex_state = 2},
  [43] = {.lex_state = 2},
  [44] = {.lex_state = 2},
  [45] = {.lex_state = 2},
  [46] = {.lex_state = 2},
  [47] = {.lex_state = 2},
  [48] = {.lex_state = 2},
  [49] = {.lex_state = 2},
  [50] = {.lex_state = 2},
  [51] = {.lex_state = 1},
  [52] = {.lex_state = 1},
  [53] = {.lex_state = 0},
  [54] = {.lex_state = 0},
  [55] = {.lex_state = 0},
  [56] = {.lex_state = 0},
  [57] = {.lex_state = 0},
  [58] = {.lex_state = 0},
  [59] = {.lex_state = 0},
  [60] = {.lex_state = 2},
};

static const uint16_t ts_parse_table[LARGE_STATE_COUNT][SYMBOL_COUNT] = {
  [0] = {
    [ts_builtin_sym_end] = ACTIONS(1),
    [anon_sym_LBRACE] = ACTIONS(1),
    [anon_sym_RBRACE] = ACTIONS(1),
    [anon_sym_if] = ACTIONS(1),
    [anon_sym_else] = ACTIONS(1),
    [anon_sym_EQ_EQ] = ACTIONS(1),
    [anon_sym_BANG_EQ] = ACTIONS(1),
    [anon_sym_GT] = ACTIONS(1),
    [anon_sym_GT_EQ] = ACTIONS(1),
    [anon_sym_LT] = ACTIONS(1),
    [anon_sym_LT_EQ] = ACTIONS(1),
    [anon_sym_PLUS] = ACTIONS(1),
    [anon_sym_DASH] = ACTIONS(1),
    [anon_sym_STAR] = ACTIONS(1),
    [anon_sym_SLASH] = ACTIONS(1),
    [anon_sym_PIPE_PIPE] = ACTIONS(1),
    [anon_sym_AMP_AMP] = ACTIONS(1),
    [anon_sym_while] = ACTIONS(1),
    [anon_sym_SEMI] = ACTIONS(1),
    [anon_sym_LPAREN] = ACTIONS(1),
    [anon_sym_RPAREN] = ACTIONS(1),
    [anon_sym_print] = ACTIONS(1),
    [anon_sym_EQ] = ACTIONS(1),
    [anon_sym_BANG] = ACTIONS(1),
    [anon_sym_nil] = ACTIONS(1),
    [anon_sym_var] = ACTIONS(1),
    [anon_sym_COMMA] = ACTIONS(1),
    [anon_sym_true] = ACTIONS(1),
    [anon_sym_false] = ACTIONS(1),
    [sym_number_literal] = ACTIONS(1),
    [sym_string_literal] = ACTIONS(1),
    [sym_variable] = ACTIONS(1),
  },
  [1] = {
    [sym_source_file] = STATE(59),
    [sym_declaration] = STATE(6),
    [sym_block] = STATE(15),
    [sym_statement] = STATE(16),
    [sym_if_statement] = STATE(15),
    [sym_while_statement] = STATE(15),
    [sym_expression_statement] = STATE(15),
    [sym_expression] = STATE(49),
    [sym_grouped_expression] = STATE(38),
    [sym_binary_expression] = STATE(38),
    [sym_print_statement] = STATE(15),
    [sym_assignment_statement] = STATE(15),
    [sym_unary_expression] = STATE(38),
    [sym_primary_expression] = STATE(38),
    [sym_variable_declaration] = STATE(16),
    [sym_boolean_literal] = STATE(29),
    [aux_sym_source_file_repeat1] = STATE(6),
    [ts_builtin_sym_end] = ACTIONS(3),
    [anon_sym_LBRACE] = ACTIONS(5),
    [anon_sym_if] = ACTIONS(7),
    [anon_sym_DASH] = ACTIONS(9),
    [anon_sym_while] = ACTIONS(11),
    [anon_sym_LPAREN] = ACTIONS(13),
    [anon_sym_print] = ACTIONS(15),
    [anon_sym_BANG] = ACTIONS(9),
    [anon_sym_nil] = ACTIONS(17),
    [anon_sym_var] = ACTIONS(19),
    [anon_sym_true] = ACTIONS(21),
    [anon_sym_false] = ACTIONS(21),
    [sym_number_literal] = ACTIONS(23),
    [sym_string_literal] = ACTIONS(23),
    [sym_variable] = ACTIONS(25),
  },
  [2] = {
    [sym_declaration] = STATE(2),
    [sym_block] = STATE(15),
    [sym_statement] = STATE(16),
    [sym_if_statement] = STATE(15),
    [sym_while_statement] = STATE(15),
    [sym_expression_statement] = STATE(15),
    [sym_expression] = STATE(49),
    [sym_grouped_expression] = STATE(38),
    [sym_binary_expression] = STATE(38),
    [sym_print_statement] = STATE(15),
    [sym_assignment_statement] = STATE(15),
    [sym_unary_expression] = STATE(38),
    [sym_primary_expression] = STATE(38),
    [sym_variable_declaration] = STATE(16),
    [sym_boolean_literal] = STATE(29),
    [aux_sym_source_file_repeat1] = STATE(2),
    [ts_builtin_sym_end] = ACTIONS(27),
    [anon_sym_LBRACE] = ACTIONS(29),
    [anon_sym_RBRACE] = ACTIONS(27),
    [anon_sym_if] = ACTIONS(32),
    [anon_sym_DASH] = ACTIONS(35),
    [anon_sym_while] = ACTIONS(38),
    [anon_sym_LPAREN] = ACTIONS(41),
    [anon_sym_print] = ACTIONS(44),
    [anon_sym_BANG] = ACTIONS(35),
    [anon_sym_nil] = ACTIONS(47),
    [anon_sym_var] = ACTIONS(50),
    [anon_sym_true] = ACTIONS(53),
    [anon_sym_false] = ACTIONS(53),
    [sym_number_literal] = ACTIONS(56),
    [sym_string_literal] = ACTIONS(56),
    [sym_variable] = ACTIONS(59),
  },
  [3] = {
    [sym_declaration] = STATE(5),
    [sym_block] = STATE(15),
    [sym_statement] = STATE(16),
    [sym_if_statement] = STATE(15),
    [sym_while_statement] = STATE(15),
    [sym_expression_statement] = STATE(15),
    [sym_expression] = STATE(49),
    [sym_grouped_expression] = STATE(38),
    [sym_binary_expression] = STATE(38),
    [sym_print_statement] = STATE(15),
    [sym_assignment_statement] = STATE(15),
    [sym_unary_expression] = STATE(38),
    [sym_primary_expression] = STATE(38),
    [sym_variable_declaration] = STATE(16),
    [sym_boolean_literal] = STATE(29),
    [aux_sym_source_file_repeat1] = STATE(5),
    [anon_sym_LBRACE] = ACTIONS(5),
    [anon_sym_RBRACE] = ACTIONS(62),
    [anon_sym_if] = ACTIONS(7),
    [anon_sym_DASH] = ACTIONS(9),
    [anon_sym_while] = ACTIONS(11),
    [anon_sym_LPAREN] = ACTIONS(13),
    [anon_sym_print] = ACTIONS(15),
    [anon_sym_BANG] = ACTIONS(9),
    [anon_sym_nil] = ACTIONS(17),
    [anon_sym_var] = ACTIONS(19),
    [anon_sym_true] = ACTIONS(21),
    [anon_sym_false] = ACTIONS(21),
    [sym_number_literal] = ACTIONS(23),
    [sym_string_literal] = ACTIONS(23),
    [sym_variable] = ACTIONS(25),
  },
  [4] = {
    [sym_declaration] = STATE(2),
    [sym_block] = STATE(15),
    [sym_statement] = STATE(16),
    [sym_if_statement] = STATE(15),
    [sym_while_statement] = STATE(15),
    [sym_expression_statement] = STATE(15),
    [sym_expression] = STATE(49),
    [sym_grouped_expression] = STATE(38),
    [sym_binary_expression] = STATE(38),
    [sym_print_statement] = STATE(15),
    [sym_assignment_statement] = STATE(15),
    [sym_unary_expression] = STATE(38),
    [sym_primary_expression] = STATE(38),
    [sym_variable_declaration] = STATE(16),
    [sym_boolean_literal] = STATE(29),
    [aux_sym_source_file_repeat1] = STATE(2),
    [anon_sym_LBRACE] = ACTIONS(5),
    [anon_sym_RBRACE] = ACTIONS(64),
    [anon_sym_if] = ACTIONS(7),
    [anon_sym_DASH] = ACTIONS(9),
    [anon_sym_while] = ACTIONS(11),
    [anon_sym_LPAREN] = ACTIONS(13),
    [anon_sym_print] = ACTIONS(15),
    [anon_sym_BANG] = ACTIONS(9),
    [anon_sym_nil] = ACTIONS(17),
    [anon_sym_var] = ACTIONS(19),
    [anon_sym_true] = ACTIONS(21),
    [anon_sym_false] = ACTIONS(21),
    [sym_number_literal] = ACTIONS(23),
    [sym_string_literal] = ACTIONS(23),
    [sym_variable] = ACTIONS(25),
  },
  [5] = {
    [sym_declaration] = STATE(2),
    [sym_block] = STATE(15),
    [sym_statement] = STATE(16),
    [sym_if_statement] = STATE(15),
    [sym_while_statement] = STATE(15),
    [sym_expression_statement] = STATE(15),
    [sym_expression] = STATE(49),
    [sym_grouped_expression] = STATE(38),
    [sym_binary_expression] = STATE(38),
    [sym_print_statement] = STATE(15),
    [sym_assignment_statement] = STATE(15),
    [sym_unary_expression] = STATE(38),
    [sym_primary_expression] = STATE(38),
    [sym_variable_declaration] = STATE(16),
    [sym_boolean_literal] = STATE(29),
    [aux_sym_source_file_repeat1] = STATE(2),
    [anon_sym_LBRACE] = ACTIONS(5),
    [anon_sym_RBRACE] = ACTIONS(66),
    [anon_sym_if] = ACTIONS(7),
    [anon_sym_DASH] = ACTIONS(9),
    [anon_sym_while] = ACTIONS(11),
    [anon_sym_LPAREN] = ACTIONS(13),
    [anon_sym_print] = ACTIONS(15),
    [anon_sym_BANG] = ACTIONS(9),
    [anon_sym_nil] = ACTIONS(17),
    [anon_sym_var] = ACTIONS(19),
    [anon_sym_true] = ACTIONS(21),
    [anon_sym_false] = ACTIONS(21),
    [sym_number_literal] = ACTIONS(23),
    [sym_string_literal] = ACTIONS(23),
    [sym_variable] = ACTIONS(25),
  },
  [6] = {
    [sym_declaration] = STATE(2),
    [sym_block] = STATE(15),
    [sym_statement] = STATE(16),
    [sym_if_statement] = STATE(15),
    [sym_while_statement] = STATE(15),
    [sym_expression_statement] = STATE(15),
    [sym_expression] = STATE(49),
    [sym_grouped_expression] = STATE(38),
    [sym_binary_expression] = STATE(38),
    [sym_print_statement] = STATE(15),
    [sym_assignment_statement] = STATE(15),
    [sym_unary_expression] = STATE(38),
    [sym_primary_expression] = STATE(38),
    [sym_variable_declaration] = STATE(16),
    [sym_boolean_literal] = STATE(29),
    [aux_sym_source_file_repeat1] = STATE(2),
    [ts_builtin_sym_end] = ACTIONS(68),
    [anon_sym_LBRACE] = ACTIONS(5),
    [anon_sym_if] = ACTIONS(7),
    [anon_sym_DASH] = ACTIONS(9),
    [anon_sym_while] = ACTIONS(11),
    [anon_sym_LPAREN] = ACTIONS(13),
    [anon_sym_print] = ACTIONS(15),
    [anon_sym_BANG] = ACTIONS(9),
    [anon_sym_nil] = ACTIONS(17),
    [anon_sym_var] = ACTIONS(19),
    [anon_sym_true] = ACTIONS(21),
    [anon_sym_false] = ACTIONS(21),
    [sym_number_literal] = ACTIONS(23),
    [sym_string_literal] = ACTIONS(23),
    [sym_variable] = ACTIONS(25),
  },
  [7] = {
    [sym_declaration] = STATE(4),
    [sym_block] = STATE(15),
    [sym_statement] = STATE(16),
    [sym_if_statement] = STATE(15),
    [sym_while_statement] = STATE(15),
    [sym_expression_statement] = STATE(15),
    [sym_expression] = STATE(49),
    [sym_grouped_expression] = STATE(38),
    [sym_binary_expression] = STATE(38),
    [sym_print_statement] = STATE(15),
    [sym_assignment_statement] = STATE(15),
    [sym_unary_expression] = STATE(38),
    [sym_primary_expression] = STATE(38),
    [sym_variable_declaration] = STATE(16),
    [sym_boolean_literal] = STATE(29),
    [aux_sym_source_file_repeat1] = STATE(4),
    [anon_sym_LBRACE] = ACTIONS(5),
    [anon_sym_RBRACE] = ACTIONS(70),
    [anon_sym_if] = ACTIONS(7),
    [anon_sym_DASH] = ACTIONS(9),
    [anon_sym_while] = ACTIONS(11),
    [anon_sym_LPAREN] = ACTIONS(13),
    [anon_sym_print] = ACTIONS(15),
    [anon_sym_BANG] = ACTIONS(9),
    [anon_sym_nil] = ACTIONS(17),
    [anon_sym_var] = ACTIONS(19),
    [anon_sym_true] = ACTIONS(21),
    [anon_sym_false] = ACTIONS(21),
    [sym_number_literal] = ACTIONS(23),
    [sym_string_literal] = ACTIONS(23),
    [sym_variable] = ACTIONS(25),
  },
};

static const uint16_t ts_small_parse_table[] = {
  [0] = 4,
    ACTIONS(76), 1,
      anon_sym_else,
    STATE(13), 1,
      sym_else_statement,
    ACTIONS(72), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(74), 8,
      anon_sym_if,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [27] = 2,
    ACTIONS(78), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(80), 9,
      anon_sym_if,
      anon_sym_else,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [49] = 10,
    ACTIONS(13), 1,
      anon_sym_LPAREN,
    ACTIONS(82), 1,
      anon_sym_RPAREN,
    STATE(29), 1,
      sym_boolean_literal,
    STATE(39), 1,
      sym_expression,
    STATE(57), 1,
      sym_arguments,
    ACTIONS(9), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 2,
      anon_sym_nil,
      sym_variable,
    ACTIONS(21), 2,
      anon_sym_true,
      anon_sym_false,
    ACTIONS(23), 2,
      sym_number_literal,
      sym_string_literal,
    STATE(38), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [87] = 2,
    ACTIONS(84), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(86), 9,
      anon_sym_if,
      anon_sym_else,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [109] = 2,
    ACTIONS(78), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(80), 8,
      anon_sym_if,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [130] = 2,
    ACTIONS(88), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(90), 8,
      anon_sym_if,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [151] = 2,
    ACTIONS(92), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(94), 8,
      anon_sym_if,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [172] = 2,
    ACTIONS(96), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(98), 8,
      anon_sym_if,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [193] = 2,
    ACTIONS(100), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(102), 8,
      anon_sym_if,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [214] = 2,
    ACTIONS(104), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(106), 8,
      anon_sym_if,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [235] = 2,
    ACTIONS(108), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(110), 8,
      anon_sym_if,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [256] = 4,
    ACTIONS(116), 1,
      anon_sym_LPAREN,
    STATE(24), 1,
      aux_sym_call_repeat1,
    ACTIONS(114), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(112), 12,
      anon_sym_LBRACE,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_SEMI,
      anon_sym_RPAREN,
      anon_sym_COMMA,
  [281] = 2,
    ACTIONS(84), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(86), 8,
      anon_sym_if,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [302] = 2,
    ACTIONS(118), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(120), 8,
      anon_sym_if,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [323] = 2,
    ACTIONS(122), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(124), 8,
      anon_sym_if,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [344] = 2,
    ACTIONS(126), 8,
      ts_builtin_sym_end,
      anon_sym_LBRACE,
      anon_sym_RBRACE,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
    ACTIONS(128), 8,
      anon_sym_if,
      anon_sym_while,
      anon_sym_print,
      anon_sym_nil,
      anon_sym_var,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
  [365] = 4,
    ACTIONS(134), 1,
      anon_sym_LPAREN,
    STATE(24), 1,
      aux_sym_call_repeat1,
    ACTIONS(132), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(130), 12,
      anon_sym_LBRACE,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_SEMI,
      anon_sym_RPAREN,
      anon_sym_COMMA,
  [390] = 2,
    ACTIONS(132), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(130), 13,
      anon_sym_LBRACE,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_SEMI,
      anon_sym_LPAREN,
      anon_sym_RPAREN,
      anon_sym_COMMA,
  [410] = 2,
    ACTIONS(139), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(137), 13,
      anon_sym_LBRACE,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_SEMI,
      anon_sym_LPAREN,
      anon_sym_RPAREN,
      anon_sym_COMMA,
  [430] = 8,
    ACTIONS(13), 1,
      anon_sym_LPAREN,
    STATE(29), 1,
      sym_boolean_literal,
    STATE(48), 1,
      sym_expression,
    ACTIONS(9), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 2,
      anon_sym_nil,
      sym_variable,
    ACTIONS(21), 2,
      anon_sym_true,
      anon_sym_false,
    ACTIONS(23), 2,
      sym_number_literal,
      sym_string_literal,
    STATE(38), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [462] = 3,
    STATE(30), 1,
      sym_binary_operator,
    ACTIONS(143), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(141), 12,
      anon_sym_LBRACE,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_SEMI,
      anon_sym_RPAREN,
      anon_sym_COMMA,
  [484] = 2,
    ACTIONS(147), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(145), 13,
      anon_sym_LBRACE,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_SEMI,
      anon_sym_LPAREN,
      anon_sym_RPAREN,
      anon_sym_COMMA,
  [504] = 8,
    ACTIONS(13), 1,
      anon_sym_LPAREN,
    STATE(28), 1,
      sym_expression,
    STATE(29), 1,
      sym_boolean_literal,
    ACTIONS(9), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 2,
      anon_sym_nil,
      sym_variable,
    ACTIONS(21), 2,
      anon_sym_true,
      anon_sym_false,
    ACTIONS(23), 2,
      sym_number_literal,
      sym_string_literal,
    STATE(38), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [536] = 8,
    ACTIONS(13), 1,
      anon_sym_LPAREN,
    STATE(29), 1,
      sym_boolean_literal,
    STATE(46), 1,
      sym_expression,
    ACTIONS(9), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 2,
      anon_sym_nil,
      sym_variable,
    ACTIONS(21), 2,
      anon_sym_true,
      anon_sym_false,
    ACTIONS(23), 2,
      sym_number_literal,
      sym_string_literal,
    STATE(38), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [568] = 8,
    ACTIONS(13), 1,
      anon_sym_LPAREN,
    STATE(29), 1,
      sym_boolean_literal,
    STATE(42), 1,
      sym_expression,
    ACTIONS(9), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 2,
      anon_sym_nil,
      sym_variable,
    ACTIONS(21), 2,
      anon_sym_true,
      anon_sym_false,
    ACTIONS(23), 2,
      sym_number_literal,
      sym_string_literal,
    STATE(38), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [600] = 8,
    ACTIONS(13), 1,
      anon_sym_LPAREN,
    STATE(29), 1,
      sym_boolean_literal,
    STATE(45), 1,
      sym_expression,
    ACTIONS(9), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 2,
      anon_sym_nil,
      sym_variable,
    ACTIONS(21), 2,
      anon_sym_true,
      anon_sym_false,
    ACTIONS(23), 2,
      sym_number_literal,
      sym_string_literal,
    STATE(38), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [632] = 8,
    ACTIONS(13), 1,
      anon_sym_LPAREN,
    STATE(29), 1,
      sym_boolean_literal,
    STATE(44), 1,
      sym_expression,
    ACTIONS(9), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 2,
      anon_sym_nil,
      sym_variable,
    ACTIONS(21), 2,
      anon_sym_true,
      anon_sym_false,
    ACTIONS(23), 2,
      sym_number_literal,
      sym_string_literal,
    STATE(38), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [664] = 2,
    ACTIONS(151), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(149), 13,
      anon_sym_LBRACE,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_SEMI,
      anon_sym_LPAREN,
      anon_sym_RPAREN,
      anon_sym_COMMA,
  [684] = 8,
    ACTIONS(13), 1,
      anon_sym_LPAREN,
    STATE(29), 1,
      sym_boolean_literal,
    STATE(43), 1,
      sym_expression,
    ACTIONS(9), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 2,
      anon_sym_nil,
      sym_variable,
    ACTIONS(21), 2,
      anon_sym_true,
      anon_sym_false,
    ACTIONS(23), 2,
      sym_number_literal,
      sym_string_literal,
    STATE(38), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [716] = 8,
    ACTIONS(13), 1,
      anon_sym_LPAREN,
    STATE(29), 1,
      sym_boolean_literal,
    STATE(47), 1,
      sym_expression,
    ACTIONS(9), 2,
      anon_sym_DASH,
      anon_sym_BANG,
    ACTIONS(17), 2,
      anon_sym_nil,
      sym_variable,
    ACTIONS(21), 2,
      anon_sym_true,
      anon_sym_false,
    ACTIONS(23), 2,
      sym_number_literal,
      sym_string_literal,
    STATE(38), 4,
      sym_grouped_expression,
      sym_binary_expression,
      sym_unary_expression,
      sym_primary_expression,
  [748] = 2,
    ACTIONS(155), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(153), 12,
      anon_sym_LBRACE,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_SEMI,
      anon_sym_RPAREN,
      anon_sym_COMMA,
  [767] = 6,
    ACTIONS(161), 1,
      anon_sym_RPAREN,
    ACTIONS(163), 1,
      anon_sym_COMMA,
    STATE(30), 1,
      sym_binary_operator,
    STATE(53), 1,
      aux_sym_arguments_repeat1,
    ACTIONS(159), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(157), 8,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
  [794] = 2,
    ACTIONS(167), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(165), 12,
      anon_sym_LBRACE,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_SEMI,
      anon_sym_RPAREN,
      anon_sym_COMMA,
  [813] = 2,
    ACTIONS(171), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(169), 12,
      anon_sym_LBRACE,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_SEMI,
      anon_sym_RPAREN,
      anon_sym_COMMA,
  [832] = 4,
    STATE(30), 1,
      sym_binary_operator,
    ACTIONS(159), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(173), 2,
      anon_sym_RPAREN,
      anon_sym_COMMA,
    ACTIONS(157), 8,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
  [854] = 5,
    ACTIONS(175), 1,
      anon_sym_LBRACE,
    STATE(8), 1,
      sym_block,
    STATE(30), 1,
      sym_binary_operator,
    ACTIONS(159), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(157), 8,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
  [878] = 5,
    ACTIONS(5), 1,
      anon_sym_LBRACE,
    STATE(18), 1,
      sym_block,
    STATE(30), 1,
      sym_binary_operator,
    ACTIONS(159), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(157), 8,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
  [902] = 4,
    ACTIONS(177), 1,
      anon_sym_RPAREN,
    STATE(30), 1,
      sym_binary_operator,
    ACTIONS(159), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(157), 8,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
  [923] = 4,
    ACTIONS(179), 1,
      anon_sym_SEMI,
    STATE(30), 1,
      sym_binary_operator,
    ACTIONS(159), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(157), 8,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
  [944] = 4,
    ACTIONS(181), 1,
      anon_sym_SEMI,
    STATE(30), 1,
      sym_binary_operator,
    ACTIONS(159), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(157), 8,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
  [965] = 4,
    ACTIONS(183), 1,
      anon_sym_SEMI,
    STATE(30), 1,
      sym_binary_operator,
    ACTIONS(159), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(157), 8,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
  [986] = 4,
    ACTIONS(185), 1,
      anon_sym_SEMI,
    STATE(30), 1,
      sym_binary_operator,
    ACTIONS(159), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(157), 8,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
  [1007] = 3,
    ACTIONS(187), 1,
      anon_sym_EQ,
    ACTIONS(147), 2,
      anon_sym_GT,
      anon_sym_LT,
    ACTIONS(145), 9,
      anon_sym_EQ_EQ,
      anon_sym_BANG_EQ,
      anon_sym_GT_EQ,
      anon_sym_LT_EQ,
      anon_sym_PLUS,
      anon_sym_DASH,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_SEMI,
  [1026] = 2,
    ACTIONS(191), 4,
      anon_sym_nil,
      anon_sym_true,
      anon_sym_false,
      sym_variable,
    ACTIONS(189), 5,
      anon_sym_DASH,
      anon_sym_LPAREN,
      anon_sym_BANG,
      sym_number_literal,
      sym_string_literal,
  [1040] = 6,
    STATE(29), 1,
      sym_boolean_literal,
    STATE(40), 1,
      sym_call,
    STATE(55), 1,
      sym_primary_expression,
    ACTIONS(17), 2,
      anon_sym_nil,
      sym_variable,
    ACTIONS(21), 2,
      anon_sym_true,
      anon_sym_false,
    ACTIONS(23), 2,
      sym_number_literal,
      sym_string_literal,
  [1062] = 3,
    ACTIONS(163), 1,
      anon_sym_COMMA,
    ACTIONS(193), 1,
      anon_sym_RPAREN,
    STATE(54), 1,
      aux_sym_arguments_repeat1,
  [1072] = 3,
    ACTIONS(173), 1,
      anon_sym_RPAREN,
    ACTIONS(195), 1,
      anon_sym_COMMA,
    STATE(54), 1,
      aux_sym_arguments_repeat1,
  [1082] = 2,
    ACTIONS(116), 1,
      anon_sym_LPAREN,
    STATE(19), 1,
      aux_sym_call_repeat1,
  [1089] = 2,
    ACTIONS(5), 1,
      anon_sym_LBRACE,
    STATE(22), 1,
      sym_block,
  [1096] = 1,
    ACTIONS(198), 1,
      anon_sym_RPAREN,
  [1100] = 1,
    ACTIONS(200), 1,
      anon_sym_EQ,
  [1104] = 1,
    ACTIONS(202), 1,
      ts_builtin_sym_end,
  [1108] = 1,
    ACTIONS(204), 1,
      sym_variable,
};

static const uint32_t ts_small_parse_table_map[] = {
  [SMALL_STATE(8)] = 0,
  [SMALL_STATE(9)] = 27,
  [SMALL_STATE(10)] = 49,
  [SMALL_STATE(11)] = 87,
  [SMALL_STATE(12)] = 109,
  [SMALL_STATE(13)] = 130,
  [SMALL_STATE(14)] = 151,
  [SMALL_STATE(15)] = 172,
  [SMALL_STATE(16)] = 193,
  [SMALL_STATE(17)] = 214,
  [SMALL_STATE(18)] = 235,
  [SMALL_STATE(19)] = 256,
  [SMALL_STATE(20)] = 281,
  [SMALL_STATE(21)] = 302,
  [SMALL_STATE(22)] = 323,
  [SMALL_STATE(23)] = 344,
  [SMALL_STATE(24)] = 365,
  [SMALL_STATE(25)] = 390,
  [SMALL_STATE(26)] = 410,
  [SMALL_STATE(27)] = 430,
  [SMALL_STATE(28)] = 462,
  [SMALL_STATE(29)] = 484,
  [SMALL_STATE(30)] = 504,
  [SMALL_STATE(31)] = 536,
  [SMALL_STATE(32)] = 568,
  [SMALL_STATE(33)] = 600,
  [SMALL_STATE(34)] = 632,
  [SMALL_STATE(35)] = 664,
  [SMALL_STATE(36)] = 684,
  [SMALL_STATE(37)] = 716,
  [SMALL_STATE(38)] = 748,
  [SMALL_STATE(39)] = 767,
  [SMALL_STATE(40)] = 794,
  [SMALL_STATE(41)] = 813,
  [SMALL_STATE(42)] = 832,
  [SMALL_STATE(43)] = 854,
  [SMALL_STATE(44)] = 878,
  [SMALL_STATE(45)] = 902,
  [SMALL_STATE(46)] = 923,
  [SMALL_STATE(47)] = 944,
  [SMALL_STATE(48)] = 965,
  [SMALL_STATE(49)] = 986,
  [SMALL_STATE(50)] = 1007,
  [SMALL_STATE(51)] = 1026,
  [SMALL_STATE(52)] = 1040,
  [SMALL_STATE(53)] = 1062,
  [SMALL_STATE(54)] = 1072,
  [SMALL_STATE(55)] = 1082,
  [SMALL_STATE(56)] = 1089,
  [SMALL_STATE(57)] = 1096,
  [SMALL_STATE(58)] = 1100,
  [SMALL_STATE(59)] = 1104,
  [SMALL_STATE(60)] = 1108,
};

static const TSParseActionEntry ts_parse_actions[] = {
  [0] = {.entry = {.count = 0, .reusable = false}},
  [1] = {.entry = {.count = 1, .reusable = false}}, RECOVER(),
  [3] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 0, 0, 0),
  [5] = {.entry = {.count = 1, .reusable = true}}, SHIFT(3),
  [7] = {.entry = {.count = 1, .reusable = false}}, SHIFT(36),
  [9] = {.entry = {.count = 1, .reusable = true}}, SHIFT(52),
  [11] = {.entry = {.count = 1, .reusable = false}}, SHIFT(34),
  [13] = {.entry = {.count = 1, .reusable = true}}, SHIFT(33),
  [15] = {.entry = {.count = 1, .reusable = false}}, SHIFT(31),
  [17] = {.entry = {.count = 1, .reusable = false}}, SHIFT(29),
  [19] = {.entry = {.count = 1, .reusable = false}}, SHIFT(60),
  [21] = {.entry = {.count = 1, .reusable = false}}, SHIFT(26),
  [23] = {.entry = {.count = 1, .reusable = true}}, SHIFT(29),
  [25] = {.entry = {.count = 1, .reusable = false}}, SHIFT(50),
  [27] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0),
  [29] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(3),
  [32] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(36),
  [35] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(52),
  [38] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(34),
  [41] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(33),
  [44] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(31),
  [47] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(29),
  [50] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(60),
  [53] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(26),
  [56] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(29),
  [59] = {.entry = {.count = 2, .reusable = false}}, REDUCE(aux_sym_source_file_repeat1, 2, 0, 0), SHIFT_REPEAT(50),
  [62] = {.entry = {.count = 1, .reusable = true}}, SHIFT(12),
  [64] = {.entry = {.count = 1, .reusable = true}}, SHIFT(11),
  [66] = {.entry = {.count = 1, .reusable = true}}, SHIFT(20),
  [68] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_source_file, 1, 0, 0),
  [70] = {.entry = {.count = 1, .reusable = true}}, SHIFT(9),
  [72] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_if_statement, 3, 0, 0),
  [74] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_if_statement, 3, 0, 0),
  [76] = {.entry = {.count = 1, .reusable = false}}, SHIFT(56),
  [78] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_block, 2, 0, 0),
  [80] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_block, 2, 0, 0),
  [82] = {.entry = {.count = 1, .reusable = true}}, SHIFT(25),
  [84] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_block, 3, 0, 0),
  [86] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_block, 3, 0, 0),
  [88] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_if_statement, 4, 0, 0),
  [90] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_if_statement, 4, 0, 0),
  [92] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_print_statement, 3, 0, 0),
  [94] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_print_statement, 3, 0, 0),
  [96] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_statement, 1, 0, 0),
  [98] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_statement, 1, 0, 0),
  [100] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_declaration, 1, 0, 0),
  [102] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_declaration, 1, 0, 0),
  [104] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_variable_declaration, 5, 0, 0),
  [106] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_variable_declaration, 5, 0, 0),
  [108] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_while_statement, 3, 0, 0),
  [110] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_while_statement, 3, 0, 0),
  [112] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_call, 2, 0, 0),
  [114] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_call, 2, 0, 0),
  [116] = {.entry = {.count = 1, .reusable = true}}, SHIFT(10),
  [118] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expression_statement, 2, 0, 0),
  [120] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_expression_statement, 2, 0, 0),
  [122] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_else_statement, 2, 0, 0),
  [124] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_else_statement, 2, 0, 0),
  [126] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_assignment_statement, 4, 0, 0),
  [128] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_assignment_statement, 4, 0, 0),
  [130] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_call_repeat1, 2, 0, 0),
  [132] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_call_repeat1, 2, 0, 0),
  [134] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_call_repeat1, 2, 0, 0), SHIFT_REPEAT(10),
  [137] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_boolean_literal, 1, 0, 0),
  [139] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_boolean_literal, 1, 0, 0),
  [141] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_binary_expression, 3, 0, 0),
  [143] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_binary_expression, 3, 0, 0),
  [145] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_primary_expression, 1, 0, 0),
  [147] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_primary_expression, 1, 0, 0),
  [149] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_call_repeat1, 3, 0, 0),
  [151] = {.entry = {.count = 1, .reusable = false}}, REDUCE(aux_sym_call_repeat1, 3, 0, 0),
  [153] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expression, 1, 0, 0),
  [155] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_expression, 1, 0, 0),
  [157] = {.entry = {.count = 1, .reusable = true}}, SHIFT(51),
  [159] = {.entry = {.count = 1, .reusable = false}}, SHIFT(51),
  [161] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_arguments, 1, 0, 0),
  [163] = {.entry = {.count = 1, .reusable = true}}, SHIFT(32),
  [165] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_unary_expression, 2, 0, 0),
  [167] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_unary_expression, 2, 0, 0),
  [169] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_grouped_expression, 3, 0, 0),
  [171] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_grouped_expression, 3, 0, 0),
  [173] = {.entry = {.count = 1, .reusable = true}}, REDUCE(aux_sym_arguments_repeat1, 2, 0, 0),
  [175] = {.entry = {.count = 1, .reusable = true}}, SHIFT(7),
  [177] = {.entry = {.count = 1, .reusable = true}}, SHIFT(41),
  [179] = {.entry = {.count = 1, .reusable = true}}, SHIFT(14),
  [181] = {.entry = {.count = 1, .reusable = true}}, SHIFT(17),
  [183] = {.entry = {.count = 1, .reusable = true}}, SHIFT(23),
  [185] = {.entry = {.count = 1, .reusable = true}}, SHIFT(21),
  [187] = {.entry = {.count = 1, .reusable = false}}, SHIFT(27),
  [189] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_binary_operator, 1, 0, 0),
  [191] = {.entry = {.count = 1, .reusable = false}}, REDUCE(sym_binary_operator, 1, 0, 0),
  [193] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_arguments, 2, 0, 0),
  [195] = {.entry = {.count = 2, .reusable = true}}, REDUCE(aux_sym_arguments_repeat1, 2, 0, 0), SHIFT_REPEAT(32),
  [198] = {.entry = {.count = 1, .reusable = true}}, SHIFT(35),
  [200] = {.entry = {.count = 1, .reusable = true}}, SHIFT(37),
  [202] = {.entry = {.count = 1, .reusable = true}},  ACCEPT_INPUT(),
  [204] = {.entry = {.count = 1, .reusable = true}}, SHIFT(58),
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
