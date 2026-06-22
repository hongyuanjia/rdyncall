#if defined(_WIN32)
#define RDYNCALL_TEST_EXPORT __declspec(dllexport)
#else
#define RDYNCALL_TEST_EXPORT __attribute__((visibility("default")))
#endif

typedef struct rdyncall_test_color_ {
  unsigned char r;
  unsigned char g;
  unsigned char b;
  unsigned char a;
} rdyncall_test_color;

typedef struct rdyncall_test_vec2_ {
  float x;
  float y;
} rdyncall_test_vec2;

typedef struct rdyncall_test_nested_vec2_ {
  rdyncall_test_vec2 xy;
} rdyncall_test_nested_vec2;

typedef struct rdyncall_test_three_double_ {
  double a;
  double b;
  double c;
} rdyncall_test_three_double;

typedef struct rdyncall_test_more_than_regs_ {
  double a;
  double b;
  double c;
  double d;
  double e;
} rdyncall_test_more_than_regs;

#define RDYNCALL_TEST_BYTES_TYPE(N) \
typedef struct rdyncall_test_bytes##N##_ { \
  unsigned char b[N]; \
} rdyncall_test_bytes##N;

RDYNCALL_TEST_BYTES_TYPE(1)
RDYNCALL_TEST_BYTES_TYPE(2)
RDYNCALL_TEST_BYTES_TYPE(4)
RDYNCALL_TEST_BYTES_TYPE(8)
RDYNCALL_TEST_BYTES_TYPE(9)
RDYNCALL_TEST_BYTES_TYPE(16)
RDYNCALL_TEST_BYTES_TYPE(17)

#define RDYNCALL_TEST_HFA_TYPE(KIND, CTYPE, N) \
typedef struct rdyncall_test_##KIND##N##_ { \
  CTYPE v[N]; \
} rdyncall_test_##KIND##N;

RDYNCALL_TEST_HFA_TYPE(float, float, 1)
RDYNCALL_TEST_HFA_TYPE(float, float, 2)
RDYNCALL_TEST_HFA_TYPE(float, float, 3)
RDYNCALL_TEST_HFA_TYPE(float, float, 4)
RDYNCALL_TEST_HFA_TYPE(float, float, 5)
RDYNCALL_TEST_HFA_TYPE(double, double, 1)
RDYNCALL_TEST_HFA_TYPE(double, double, 2)
RDYNCALL_TEST_HFA_TYPE(double, double, 3)
RDYNCALL_TEST_HFA_TYPE(double, double, 4)
RDYNCALL_TEST_HFA_TYPE(double, double, 5)

typedef struct rdyncall_test_float_int_ {
  float f;
  int i;
} rdyncall_test_float_int;

typedef struct rdyncall_test_int_float_ {
  int i;
  float f;
} rdyncall_test_int_float;

typedef struct rdyncall_test_double_int_ {
  double d;
  int i;
} rdyncall_test_double_int;

typedef struct rdyncall_test_int_double_ {
  int i;
  double d;
} rdyncall_test_int_double;

typedef struct rdyncall_test_char_double_ {
  unsigned char c;
  double d;
} rdyncall_test_char_double;

typedef union rdyncall_test_value_union_ {
  int i;
  float f;
  unsigned char c;
} rdyncall_test_value_union;

typedef struct rdyncall_test_ptr_box_ {
  int *p;
  int tag;
} rdyncall_test_ptr_box;

typedef struct rdyncall_test_bits_ {
  unsigned int a:1;
  unsigned int b:3;
  unsigned int :4;
  unsigned int c:8;
} rdyncall_test_bits;

RDYNCALL_TEST_EXPORT int rdyncall_test_color_sum(rdyncall_test_color x)
{
  return (int) x.r + 10 * (int) x.g + 100 * (int) x.b + 1000 * (int) x.a;
}

RDYNCALL_TEST_EXPORT rdyncall_test_color rdyncall_test_make_color(unsigned char r, unsigned char g, unsigned char b, unsigned char a)
{
  rdyncall_test_color x;
  x.r = r;
  x.g = g;
  x.b = b;
  x.a = a;
  return x;
}

RDYNCALL_TEST_EXPORT double rdyncall_test_vec2_sum(rdyncall_test_vec2 x)
{
  return (double) x.x + (double) x.y;
}

RDYNCALL_TEST_EXPORT rdyncall_test_vec2 rdyncall_test_make_vec2(float x, float y)
{
  rdyncall_test_vec2 out;
  out.x = x;
  out.y = y;
  return out;
}

RDYNCALL_TEST_EXPORT double rdyncall_test_nested_vec2_sum(rdyncall_test_nested_vec2 x)
{
  return (double) x.xy.x + (double) x.xy.y;
}

RDYNCALL_TEST_EXPORT rdyncall_test_nested_vec2 rdyncall_test_make_nested_vec2(float x, float y)
{
  rdyncall_test_nested_vec2 out;
  out.xy.x = x;
  out.xy.y = y;
  return out;
}

RDYNCALL_TEST_EXPORT double rdyncall_test_three_double_sum(rdyncall_test_three_double x)
{
  return x.a + x.b + x.c;
}

RDYNCALL_TEST_EXPORT rdyncall_test_three_double rdyncall_test_make_three_double(double a, double b, double c)
{
  rdyncall_test_three_double out;
  out.a = a;
  out.b = b;
  out.c = c;
  return out;
}

RDYNCALL_TEST_EXPORT double rdyncall_test_more_than_regs_sum(rdyncall_test_more_than_regs x)
{
  return x.a + x.b + x.c + x.d + x.e;
}

RDYNCALL_TEST_EXPORT rdyncall_test_more_than_regs rdyncall_test_make_more_than_regs(double base)
{
  rdyncall_test_more_than_regs out;
  out.a = base + 1.0;
  out.b = base + 2.0;
  out.c = base + 3.0;
  out.d = base + 4.0;
  out.e = base + 5.0;
  return out;
}

#define RDYNCALL_TEST_BYTES_FUNCS(N) \
RDYNCALL_TEST_EXPORT int rdyncall_test_bytes##N##_sum(rdyncall_test_bytes##N x) \
{ \
  int sum = 0; \
  int i; \
  for (i = 0; i < N; ++i) sum += (int) x.b[i]; \
  return sum; \
} \
RDYNCALL_TEST_EXPORT rdyncall_test_bytes##N rdyncall_test_make_bytes##N(unsigned char base) \
{ \
  rdyncall_test_bytes##N out; \
  int i; \
  for (i = 0; i < N; ++i) out.b[i] = (unsigned char) (base + i); \
  return out; \
}

RDYNCALL_TEST_BYTES_FUNCS(1)
RDYNCALL_TEST_BYTES_FUNCS(2)
RDYNCALL_TEST_BYTES_FUNCS(4)
RDYNCALL_TEST_BYTES_FUNCS(8)
RDYNCALL_TEST_BYTES_FUNCS(9)
RDYNCALL_TEST_BYTES_FUNCS(16)
RDYNCALL_TEST_BYTES_FUNCS(17)

#define RDYNCALL_TEST_HFA_FUNCS(KIND, CTYPE, N) \
RDYNCALL_TEST_EXPORT double rdyncall_test_##KIND##N##_sum(rdyncall_test_##KIND##N x) \
{ \
  double sum = 0.0; \
  int i; \
  for (i = 0; i < N; ++i) sum += (double) x.v[i]; \
  return sum; \
} \
RDYNCALL_TEST_EXPORT rdyncall_test_##KIND##N rdyncall_test_make_##KIND##N(CTYPE base) \
{ \
  rdyncall_test_##KIND##N out; \
  int i; \
  for (i = 0; i < N; ++i) out.v[i] = (CTYPE) (base + (CTYPE) i); \
  return out; \
}

RDYNCALL_TEST_HFA_FUNCS(float, float, 1)
RDYNCALL_TEST_HFA_FUNCS(float, float, 2)
RDYNCALL_TEST_HFA_FUNCS(float, float, 3)
RDYNCALL_TEST_HFA_FUNCS(float, float, 4)
RDYNCALL_TEST_HFA_FUNCS(float, float, 5)
RDYNCALL_TEST_HFA_FUNCS(double, double, 1)
RDYNCALL_TEST_HFA_FUNCS(double, double, 2)
RDYNCALL_TEST_HFA_FUNCS(double, double, 3)
RDYNCALL_TEST_HFA_FUNCS(double, double, 4)
RDYNCALL_TEST_HFA_FUNCS(double, double, 5)

RDYNCALL_TEST_EXPORT double rdyncall_test_float_int_sum(rdyncall_test_float_int x)
{
  return (double) x.f + (double) x.i;
}

RDYNCALL_TEST_EXPORT rdyncall_test_float_int rdyncall_test_make_float_int(float f, int i)
{
  rdyncall_test_float_int out;
  out.f = f;
  out.i = i;
  return out;
}

RDYNCALL_TEST_EXPORT double rdyncall_test_int_float_sum(rdyncall_test_int_float x)
{
  return (double) x.i + (double) x.f;
}

RDYNCALL_TEST_EXPORT rdyncall_test_int_float rdyncall_test_make_int_float(int i, float f)
{
  rdyncall_test_int_float out;
  out.i = i;
  out.f = f;
  return out;
}

RDYNCALL_TEST_EXPORT double rdyncall_test_double_int_sum(rdyncall_test_double_int x)
{
  return x.d + (double) x.i;
}

RDYNCALL_TEST_EXPORT rdyncall_test_double_int rdyncall_test_make_double_int(double d, int i)
{
  rdyncall_test_double_int out;
  out.d = d;
  out.i = i;
  return out;
}

RDYNCALL_TEST_EXPORT double rdyncall_test_int_double_sum(rdyncall_test_int_double x)
{
  return (double) x.i + x.d;
}

RDYNCALL_TEST_EXPORT rdyncall_test_int_double rdyncall_test_make_int_double(int i, double d)
{
  rdyncall_test_int_double out;
  out.i = i;
  out.d = d;
  return out;
}

RDYNCALL_TEST_EXPORT double rdyncall_test_char_double_sum(rdyncall_test_char_double x)
{
  return (double) x.c + x.d;
}

RDYNCALL_TEST_EXPORT rdyncall_test_char_double rdyncall_test_make_char_double(unsigned char c, double d)
{
  rdyncall_test_char_double out;
  out.c = c;
  out.d = d;
  return out;
}

RDYNCALL_TEST_EXPORT int rdyncall_test_exhaust_ints_color_sum(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7, rdyncall_test_color x)
{
  return a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + rdyncall_test_color_sum(x);
}

RDYNCALL_TEST_EXPORT double rdyncall_test_exhaust_fp_vec2_sum(double a0, double a1, double a2, double a3, double a4, double a5, double a6, double a7, rdyncall_test_vec2 x)
{
  return a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + rdyncall_test_vec2_sum(x);
}

RDYNCALL_TEST_EXPORT int rdyncall_test_value_union_int(rdyncall_test_value_union x)
{
  return x.i;
}

RDYNCALL_TEST_EXPORT rdyncall_test_value_union rdyncall_test_make_value_union_int(int x)
{
  rdyncall_test_value_union out;
  out.i = x;
  return out;
}

RDYNCALL_TEST_EXPORT int rdyncall_test_ptr_box_sum(rdyncall_test_ptr_box x)
{
  return (x.p ? *x.p : 0) + x.tag;
}

RDYNCALL_TEST_EXPORT int rdyncall_test_bits_sum(rdyncall_test_bits x)
{
  return (int) x.a + 10 * (int) x.b + 100 * (int) x.c;
}

RDYNCALL_TEST_EXPORT rdyncall_test_bits rdyncall_test_make_bits(unsigned int a, unsigned int b, unsigned int c)
{
  rdyncall_test_bits out;
  out.a = a;
  out.b = b;
  out.c = c;
  return out;
}
