#include <stddef.h>

int rdyncall_arg_ptr_is_null(void *p)
{
  return p == NULL;
}

int rdyncall_arg_ptr_is_nonnull(void *p)
{
  return p != NULL;
}

int rdyncall_arg_int_ptr_value(int *p)
{
  return p == NULL ? -1 : *p;
}

int rdyncall_arg_double_ptr_nonnull(double *p)
{
  return p != NULL;
}

int rdyncall_arg_float_ptr_nonnull(float *p)
{
  return p != NULL;
}

int rdyncall_arg_char_ptr_nonnull(char *p)
{
  return p != NULL;
}

int rdyncall_arg_short_ptr_nonnull(short *p)
{
  return p != NULL;
}

int rdyncall_arg_ptrptr_nonnull(void **p)
{
  return p != NULL;
}
