#//////////////////////////////////////////////////////////////////////
#
#	win32screeninfo.rb
#	Copyright 2007 Tassilo Philipp
#
#	Dyncall sample loading user32.dll on windows and displaying a
#	native windows message box by calling MessageBoxA(...).
#
#///////////////////////////////////////////////////////////////////////

require 'rbdc'

l = Dyncall::ExtLib.new
if l.load('user32') != nil
  puts 'width:                ' + l.call(:GetSystemMetrics, 'i)i',  0).to_s
  puts 'height:               ' + l.call(:GetSystemMetrics, 'i)i',  1).to_s
  puts 'number of monitors:   ' + l.call(:GetSystemMetrics, 'i)i', 80).to_s
end
