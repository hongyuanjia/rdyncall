#include <stdarg.h>

int rdyncall_dynbind_add(int x, int y)
{
    return x + y;
}

int rdyncall_dynbind_sum_variadic(int x, ...)
{
    va_list args;
    int y;
    int z;

    va_start(args, x);
    y = va_arg(args, int);
    z = va_arg(args, int);
    va_end(args);

    return x + y + z;
}

double rdyncall_dynbind_sum_variadic_double(double x, ...)
{
    va_list args;
    double y;

    va_start(args, x);
    y = va_arg(args, double);
    va_end(args);

    return x + y;
}
