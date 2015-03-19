DG = require "ldynguess"
require "dynport"
if DG.os == "osx" then
  dynport "cocoautil"
  CocoaInit() 
end

