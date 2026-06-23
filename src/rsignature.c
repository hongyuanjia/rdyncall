/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rsignature.c
 ** Description: signature tokenizer
 **/

#include <limits.h>
#include <string.h>

#include <Rinternals.h>
#include <R_ext/Error.h>

typedef struct {
  const char *text;
  int length;
} rsignature_input;

static rsignature_input rsignature_get_input(SEXP x, const char *name)
{
  rsignature_input input;
  size_t length;

  if (!isString(x) || XLENGTH(x) != 1 || STRING_ELT(x, 0) == NA_STRING) {
    error("%s must be a single character string", name);
  }

  input.text = CHAR(STRING_ELT(x, 0));
  length = strlen(input.text);
  if (length > INT_MAX) {
    error("%s is too long", name);
  }
  input.length = (int) length;
  return input;
}

static int rsignature_is_space(char c)
{
  return c == ' ' || c == '\n' || c == '\t';
}

static void rsignature_set_slice(SEXP x, int index, const char *source,
                                 int start, int end)
{
  SET_STRING_ELT(x, index, mkCharLenCE(source + start, end - start, CE_NATIVE));
}

static int rsignature_parse_decimal(const char *source, int start, int end,
                                    int allow_zero, int *value)
{
  long parsed = 0;
  int i;

  if (start >= end) {
    return 0;
  }
  if (source[start] < '0' || source[start] > '9') {
    return 0;
  }
  if (source[start] == '0' && (!allow_zero || start + 1 < end)) {
    return 0;
  }

  for (i = start; i < end; ++i) {
    int digit;
    if (source[i] < '0' || source[i] > '9') {
      return 0;
    }
    digit = source[i] - '0';
    if (parsed > INT_MAX / 10L ||
        (parsed == INT_MAX / 10L && digit > INT_MAX % 10L)) {
      return 0;
    }
    parsed = parsed * 10L + digit;
  }

  *value = (int) parsed;
  return 1;
}

static void rsignature_set_error_metadata(SEXP out, int reason_index,
                                          int start_index, int end_index,
                                          const char *reason, int start, int end)
{
  SET_VECTOR_ELT(out, reason_index, mkString(reason));
  SET_VECTOR_ELT(out, start_index, ScalarInteger(start));
  SET_VECTOR_ELT(out, end_index, ScalarInteger(end));
}

static void rsignature_set_error_metadata_names(SEXP names, int reason_index,
                                                int start_index, int end_index)
{
  SET_STRING_ELT(names, reason_index, mkChar("error_reason"));
  SET_STRING_ELT(names, start_index, mkChar("error_start"));
  SET_STRING_ELT(names, end_index, mkChar("error_end"));
}

static SEXP rsignature_make_success(SEXP types, SEXP array_lens,
                                    SEXP starts, SEXP ends, int count)
{
  SEXP out, names, out_types, out_array_lens, out_starts, out_ends;
  int i;

  PROTECT(out_types = allocVector(STRSXP, count));
  PROTECT(out_array_lens = allocVector(INTSXP, count));
  PROTECT(out_starts = allocVector(INTSXP, count));
  PROTECT(out_ends = allocVector(INTSXP, count));

  for (i = 0; i < count; ++i) {
    SET_STRING_ELT(out_types, i, STRING_ELT(types, i));
    INTEGER(out_array_lens)[i] = INTEGER(array_lens)[i];
    INTEGER(out_starts)[i] = INTEGER(starts)[i];
    INTEGER(out_ends)[i] = INTEGER(ends)[i];
  }

  PROTECT(out = allocVector(VECSXP, 5));
  SET_VECTOR_ELT(out, 0, ScalarLogical(1));
  SET_VECTOR_ELT(out, 1, out_types);
  SET_VECTOR_ELT(out, 2, out_array_lens);
  SET_VECTOR_ELT(out, 3, out_starts);
  SET_VECTOR_ELT(out, 4, out_ends);

  PROTECT(names = allocVector(STRSXP, 5));
  SET_STRING_ELT(names, 0, mkChar("ok"));
  SET_STRING_ELT(names, 1, mkChar("type"));
  SET_STRING_ELT(names, 2, mkChar("array_len"));
  SET_STRING_ELT(names, 3, mkChar("start"));
  SET_STRING_ELT(names, 4, mkChar("end"));
  setAttrib(out, R_NamesSymbol, names);

  UNPROTECT(6);
  return out;
}

static SEXP rsignature_make_error(const char *reason, int start, int end)
{
  SEXP out, names;

  PROTECT(out = allocVector(VECSXP, 8));
  SET_VECTOR_ELT(out, 0, ScalarLogical(0));
  SET_VECTOR_ELT(out, 1, allocVector(STRSXP, 0));
  SET_VECTOR_ELT(out, 2, allocVector(INTSXP, 0));
  SET_VECTOR_ELT(out, 3, allocVector(INTSXP, 0));
  SET_VECTOR_ELT(out, 4, allocVector(INTSXP, 0));
  rsignature_set_error_metadata(out, 5, 6, 7, reason, start, end);

  PROTECT(names = allocVector(STRSXP, 8));
  SET_STRING_ELT(names, 0, mkChar("ok"));
  SET_STRING_ELT(names, 1, mkChar("type"));
  SET_STRING_ELT(names, 2, mkChar("array_len"));
  SET_STRING_ELT(names, 3, mkChar("start"));
  SET_STRING_ELT(names, 4, mkChar("end"));
  rsignature_set_error_metadata_names(names, 5, 6, 7);
  setAttrib(out, R_NamesSymbol, names);

  UNPROTECT(2);
  return out;
}

static SEXP rsignature_make_field_tail_success(SEXP field_names, SEXP bit_widths,
                                               SEXP field_starts, SEXP field_ends,
                                               int field_count, SEXP directives,
                                               SEXP directive_starts,
                                               SEXP directive_ends,
                                               int directive_count)
{
  SEXP out, names, out_field_names, out_bit_widths, out_field_starts;
  SEXP out_field_ends, out_directives, out_directive_starts, out_directive_ends;
  int i;

  PROTECT(out_field_names = allocVector(STRSXP, field_count));
  PROTECT(out_bit_widths = allocVector(INTSXP, field_count));
  PROTECT(out_field_starts = allocVector(INTSXP, field_count));
  PROTECT(out_field_ends = allocVector(INTSXP, field_count));
  PROTECT(out_directives = allocVector(STRSXP, directive_count));
  PROTECT(out_directive_starts = allocVector(INTSXP, directive_count));
  PROTECT(out_directive_ends = allocVector(INTSXP, directive_count));

  for (i = 0; i < field_count; ++i) {
    SET_STRING_ELT(out_field_names, i, STRING_ELT(field_names, i));
    INTEGER(out_bit_widths)[i] = INTEGER(bit_widths)[i];
    INTEGER(out_field_starts)[i] = INTEGER(field_starts)[i];
    INTEGER(out_field_ends)[i] = INTEGER(field_ends)[i];
  }

  for (i = 0; i < directive_count; ++i) {
    SET_STRING_ELT(out_directives, i, STRING_ELT(directives, i));
    INTEGER(out_directive_starts)[i] = INTEGER(directive_starts)[i];
    INTEGER(out_directive_ends)[i] = INTEGER(directive_ends)[i];
  }

  PROTECT(out = allocVector(VECSXP, 8));
  SET_VECTOR_ELT(out, 0, ScalarLogical(1));
  SET_VECTOR_ELT(out, 1, out_field_names);
  SET_VECTOR_ELT(out, 2, out_bit_widths);
  SET_VECTOR_ELT(out, 3, out_field_starts);
  SET_VECTOR_ELT(out, 4, out_field_ends);
  SET_VECTOR_ELT(out, 5, out_directives);
  SET_VECTOR_ELT(out, 6, out_directive_starts);
  SET_VECTOR_ELT(out, 7, out_directive_ends);

  PROTECT(names = allocVector(STRSXP, 8));
  SET_STRING_ELT(names, 0, mkChar("ok"));
  SET_STRING_ELT(names, 1, mkChar("field_name"));
  SET_STRING_ELT(names, 2, mkChar("bit_width"));
  SET_STRING_ELT(names, 3, mkChar("field_start"));
  SET_STRING_ELT(names, 4, mkChar("field_end"));
  SET_STRING_ELT(names, 5, mkChar("directive"));
  SET_STRING_ELT(names, 6, mkChar("directive_start"));
  SET_STRING_ELT(names, 7, mkChar("directive_end"));
  setAttrib(out, R_NamesSymbol, names);

  UNPROTECT(9);
  return out;
}

static SEXP rsignature_make_field_tail_error(const char *reason, int start, int end)
{
  SEXP out, names;

  PROTECT(out = allocVector(VECSXP, 11));
  SET_VECTOR_ELT(out, 0, ScalarLogical(0));
  SET_VECTOR_ELT(out, 1, allocVector(STRSXP, 0));
  SET_VECTOR_ELT(out, 2, allocVector(INTSXP, 0));
  SET_VECTOR_ELT(out, 3, allocVector(INTSXP, 0));
  SET_VECTOR_ELT(out, 4, allocVector(INTSXP, 0));
  SET_VECTOR_ELT(out, 5, allocVector(STRSXP, 0));
  SET_VECTOR_ELT(out, 6, allocVector(INTSXP, 0));
  SET_VECTOR_ELT(out, 7, allocVector(INTSXP, 0));
  rsignature_set_error_metadata(out, 8, 9, 10, reason, start, end);

  PROTECT(names = allocVector(STRSXP, 11));
  SET_STRING_ELT(names, 0, mkChar("ok"));
  SET_STRING_ELT(names, 1, mkChar("field_name"));
  SET_STRING_ELT(names, 2, mkChar("bit_width"));
  SET_STRING_ELT(names, 3, mkChar("field_start"));
  SET_STRING_ELT(names, 4, mkChar("field_end"));
  SET_STRING_ELT(names, 5, mkChar("directive"));
  SET_STRING_ELT(names, 6, mkChar("directive_start"));
  SET_STRING_ELT(names, 7, mkChar("directive_end"));
  rsignature_set_error_metadata_names(names, 8, 9, 10);
  setAttrib(out, R_NamesSymbol, names);

  UNPROTECT(2);
  return out;
}

SEXP C_scan_signature_tokens(SEXP signature_x)
{
  SEXP types, array_lens, starts, ends, out;
  rsignature_input input;
  const char *signature;
  int n, i, count;

  input = rsignature_get_input(signature_x, "signature");
  signature = input.text;
  n = input.length;
  i = 0;
  count = 0;

  PROTECT(types = allocVector(STRSXP, n));
  PROTECT(array_lens = allocVector(INTSXP, n));
  PROTECT(starts = allocVector(INTSXP, n));
  PROTECT(ends = allocVector(INTSXP, n));

  while (i < n) {
    int token_start = i;
    int type_end;
    int array_len = 1;

    while (i < n && signature[i] == '*') {
      ++i;
    }

    if (i >= n) {
      type_end = n - 1;
      i = n;
    } else if (signature[i] == '<') {
      ++i;
      while (i < n && signature[i] != '>') {
        ++i;
      }
      if (i >= n) {
        out = rsignature_make_error("aggregate", token_start + 1, n + 1);
        UNPROTECT(4);
        return out;
      }
      type_end = i;
      ++i;
    } else {
      type_end = i;
      ++i;
    }

    while (i < n && signature[i] == '[') {
      int array_start = i;
      int value_start;
      int close;
      int value;

      ++i;
      value_start = i;

      close = i;
      while (close < n && signature[close] != ']') {
        ++close;
      }
      if (close >= n) {
        out = rsignature_make_error("array", token_start + 1, n);
        UNPROTECT(4);
        return out;
      }

      if (!rsignature_parse_decimal(signature, value_start, close, 0, &value) ||
          array_len > INT_MAX / value) {
        out = rsignature_make_error("array", array_start + 1, close + 1);
        UNPROTECT(4);
        return out;
      }

      array_len *= (int) value;
      i = close + 1;
    }

    rsignature_set_slice(types, count, signature, token_start, type_end + 1);
    INTEGER(array_lens)[count] = array_len;
    INTEGER(starts)[count] = token_start + 1;
    INTEGER(ends)[count] = i;
    ++count;
  }

  out = rsignature_make_success(types, array_lens, starts, ends, count);
  UNPROTECT(4);
  return out;
}

SEXP C_scan_field_tail(SEXP tail_x)
{
  SEXP field_names, bit_widths, field_starts, field_ends;
  SEXP directives, directive_starts, directive_ends, out;
  rsignature_input input;
  const char *tail;
  int n, i, field_count, directive_count;

  input = rsignature_get_input(tail_x, "field tail");
  tail = input.text;
  n = input.length;
  i = 0;
  field_count = 0;
  directive_count = 0;

  PROTECT(field_names = allocVector(STRSXP, n));
  PROTECT(bit_widths = allocVector(INTSXP, n));
  PROTECT(field_starts = allocVector(INTSXP, n));
  PROTECT(field_ends = allocVector(INTSXP, n));
  PROTECT(directives = allocVector(STRSXP, n));
  PROTECT(directive_starts = allocVector(INTSXP, n));
  PROTECT(directive_ends = allocVector(INTSXP, n));

  while (i < n) {
    int token_start;
    int token_end;
    int colon_count = 0;
    int colon_pos = -1;
    int j;

    while (i < n && rsignature_is_space(tail[i])) {
      ++i;
    }
    if (i >= n) {
      break;
    }

    token_start = i;
    while (i < n && !rsignature_is_space(tail[i])) {
      ++i;
    }
    token_end = i - 1;

    if (tail[token_start] == '@') {
      rsignature_set_slice(directives, directive_count, tail, token_start, token_end + 1);
      INTEGER(directive_starts)[directive_count] = token_start + 1;
      INTEGER(directive_ends)[directive_count] = token_end + 1;
      ++directive_count;
      continue;
    }

    for (j = token_start; j <= token_end; ++j) {
      if (tail[j] == ':') {
        ++colon_count;
        colon_pos = j;
      }
    }

    if (colon_count == 0) {
      rsignature_set_slice(field_names, field_count, tail, token_start, token_end + 1);
      INTEGER(bit_widths)[field_count] = NA_INTEGER;
    } else {
      int value_start;
      int value;

      if (colon_count != 1) {
        out = rsignature_make_field_tail_error("bitfield_spec", token_start + 1, token_end + 1);
        UNPROTECT(7);
        return out;
      }

      value_start = colon_pos + 1;
      if (value_start > token_end) {
        out = rsignature_make_field_tail_error("bitfield_width", token_start + 1, token_end + 1);
        UNPROTECT(7);
        return out;
      }

      if (!rsignature_parse_decimal(tail, value_start, token_end + 1, 1, &value)) {
        out = rsignature_make_field_tail_error("bitfield_width", token_start + 1, token_end + 1);
        UNPROTECT(7);
        return out;
      }

      rsignature_set_slice(field_names, field_count, tail, token_start, colon_pos);
      INTEGER(bit_widths)[field_count] = value;
    }

    INTEGER(field_starts)[field_count] = token_start + 1;
    INTEGER(field_ends)[field_count] = token_end + 1;
    ++field_count;
  }

  out = rsignature_make_field_tail_success(
    field_names, bit_widths, field_starts, field_ends, field_count,
    directives, directive_starts, directive_ends, directive_count
  );
  UNPROTECT(7);
  return out;
}
