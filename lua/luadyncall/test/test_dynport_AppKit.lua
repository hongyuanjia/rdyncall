require"dynport"
AppKit = dynport("AppKit")
local success = AppKit.NSApplicationLoad()
print("success="..tostring(success))

