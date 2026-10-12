/* The sentinel changes only after the foreign callback returns normally. */
int m0_callback_boundary(int (*callback)(void), int *sentinel)
{
    int result = callback();
    *sentinel = 123;
    return result;
}

/* Different input/return layouts expose a skipped argument descriptor on disabled reuse. */
typedef struct { int x; } BoundaryInput;
typedef struct { double x, y; } BoundaryPair;

/* The pair returns in two floating registers where the platform ABI supports them. */
BoundaryPair m0_pair_boundary(BoundaryPair (*callback)(BoundaryInput), BoundaryInput input)
{
    return callback(input);
}
