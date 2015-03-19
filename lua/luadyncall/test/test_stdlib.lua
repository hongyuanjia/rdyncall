require "dynport"
dynport("stdlib")

function checkmalloc(size)
  local ptr = malloc(size)
  if ptr == NULL then
    print("FAILED")
  else
    print("SUCCESS",ptr)
  end
end
checkmalloc(-1)
checkmalloc(0)
checkmalloc(10)


