# Package: rdyncall 
# File: demo/sqrt.R
# Description: C math library demo (dynbind demo) 

dynbind( c("msvcrt","m","m.so.6"), "sqrt(d)d;" )
print(sqrt)
sqrt(144)

