#include <errno.h>
#include <stdarg.h>
#if defined(_WIN32)
#include <windows.h>
#endif

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

/* Set errno and return a caller-selected value for rdyncall capture tests. */
int rdyncall_dynbind_set_errno_return(int code, int result)
{
    errno = code;
    return result;
}

/* Return the current process errno so tests can verify slot seeding. */
int rdyncall_dynbind_return_errno(void)
{
    return errno;
}

#if defined(_WIN32)
/* Set Windows LastError and return a caller-selected value for capture tests. */
int rdyncall_dynbind_set_last_error_return(int code, int result)
{
    SetLastError((DWORD) code);
    return result;
}
#endif
