--- Get type information from type signature.
--
-- @param typesignature string representing type informations. Fundamental type signatures are represented by characters such as 'c' for C char, 's' for C short, 'i' for C int, 'j' for C long
-- 'l' for C long long, 'f' for C float, 'd' for C double, 'p' for C pointer,
-- 'B' for ISO C99 _Bool_t/C++ bool, 'v' for C void. Upper-case characters 'CSIJL' refer to the corresponding unsigned C type.
-- Function signature syntax: 'name(argtypes..)resulttypes..;'
-- Structure signature syntax: 'name{fieldtypes..)fieldnames..;' the fieldnames are space separated text tokens.
-- Named objects can be refered using '<name>' syntax.
-- pointer types can be specified by prefixing multiple '*'.
function typeinfo(typesignature)
end


