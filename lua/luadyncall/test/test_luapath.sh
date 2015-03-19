test_unset() {
  echo "TEST: <unset>"
  lua test_luapath.lua
  echo 
}

test_set() {
  echo "TEST: LUA_PATH=$1"
  LUA_PATH=$1 lua test_luapath.lua
  echo 
}

test_unset
test_set "" 
test_set ";;"
test_set "AA;;BB"

