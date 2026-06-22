/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rsignature.c
 ** Description: signature tokenizer
 **/

#include <limits.h>
#include <string.h>

#include <Rinternals.h>
#include <R_ext/Error.h>

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
  SET_VECTOR_ELT(out, 5, mkString(reason));
  SET_VECTOR_ELT(out, 6, ScalarInteger(start));
  SET_VECTOR_ELT(out, 7, ScalarInteger(end));

  PROTECT(names = allocVector(STRSXP, 8));
  SET_STRING_ELT(names, 0, mkChar("ok"));
  SET_STRING_ELT(names, 1, mkChar("type"));
  SET_STRING_ELT(names, 2, mkChar("array_len"));
  SET_STRING_ELT(names, 3, mkChar("start"));
  SET_STRING_ELT(names, 4, mkChar("end"));
  SET_STRING_ELT(names, 5, mkChar("error_reason"));
  SET_STRING_ELT(names, 6, mkChar("error_start"));
  SET_STRING_ELT(names, 7, mkChar("error_end"));
  setAttrib(out, R_NamesSymbol, names);

  UNPROTECT(2);
  return out;
}

SEXP C_scan_signature_tokens(SEXP signature_x)
{
  SEXP types, array_lens, starts, ends, out;
  const char *signature;
  size_t length;
  int n, i, count;

  if (!isString(signature_x) || XLENGTH(signature_x) != 1 ||
      STRING_ELT(signature_x, 0) == NA_STRING) {
    error("signature must be a single character string");
  }

  signature = CHAR(STRING_ELT(signature_x, 0));
  length = strlen(signature);
  if (length > INT_MAX) {
    error("signature is too long");
  }
  n = (int) length;
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
      int j;
      long value = 0;

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

      if (value_start >= close ||
          signature[value_start] < '1' || signature[value_start] > '9') {
        out = rsignature_make_error("array", array_start + 1, close + 1);
        UNPROTECT(4);
        return out;
      }

      for (j = value_start; j < close; ++j) {
        int digit;
        if (signature[j] < '0' || signature[j] > '9') {
          out = rsignature_make_error("array", array_start + 1, close + 1);
          UNPROTECT(4);
          return out;
        }

        digit = signature[j] - '0';
        if (value > INT_MAX / 10L ||
            (value == INT_MAX / 10L && digit > INT_MAX % 10L)) {
          out = rsignature_make_error("array", array_start + 1, close + 1);
          UNPROTECT(4);
          return out;
        }
        value = value * 10L + digit;
      }

      if (array_len > INT_MAX / value) {
        out = rsignature_make_error("array", array_start + 1, close + 1);
        UNPROTECT(4);
        return out;
      }

      array_len *= (int) value;
      i = close + 1;
    }

    SET_STRING_ELT(types, count,
      mkCharLenCE(signature + token_start, type_end - token_start + 1, CE_NATIVE));
    INTEGER(array_lens)[count] = array_len;
    INTEGER(starts)[count] = token_start + 1;
    INTEGER(ends)[count] = i;
    ++count;
  }

  out = rsignature_make_success(types, array_lens, starts, ends, count);
  UNPROTECT(4);
  return out;
}
