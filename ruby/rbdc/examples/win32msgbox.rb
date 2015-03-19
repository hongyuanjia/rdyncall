#//////////////////////////////////////////////////////////////////////
#
#	win32msgbox.rb
#	Copyright 2007-2014 Tassilo Philipp
#
#	Dyncall sample loading user32.dll on windows, listing all user32
#   symbols and displaying a #	native windows message box by calling
#   MessageBoxA(...).
#
#///////////////////////////////////////////////////////////////////////

require 'rbdc'

l = Dyncall::ExtLib.new
if l.load('user32') != nil and l.syms_init('user32')
	l.syms_each { |s| puts s }
	puts l.syms_count
	puts l.exists?(:NonExistant)
	puts l.exists?(:MessageBoxA)
	puts l.call(:MessageBoxA, 'IZZI)i', 0, 'Hello world from dyncall!', 'dyncall demo', 0)
	# @@@ check puts on dyncall called function returning a void... crashes e.g. change above signature to IZZI)v
end
