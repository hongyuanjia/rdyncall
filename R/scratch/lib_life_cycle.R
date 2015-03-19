# manage by auto-reference?

# package foo uses dynport bar
#
# 1. dynport bar loaded - loads bar shared library
# 2. package foo uses bar
# 3. copy function from dynport
# 3. detach dynport bar
# 4. 
