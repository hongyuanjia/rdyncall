#//////////////////////////////////////////////////////////////////////
#
#	unix_math.rb
#	Copyright 2015 Tassilo Philipp
#
#	Dyncall sample loading libm and calling functions
#
#///////////////////////////////////////////////////////////////////////

require 'rbdc'

l = Dyncall::ExtLib.new
if l.load('/usr/lib/libm.so') != nil and l.syms_init('/usr/lib/libm.so') != nil
  puts 'Symbols in libm: '+l.syms_count.to_s
  puts 'All symbol names in libm:'
  l.syms_each { |s| puts s }

  puts 'libm has sqrtf()? '       + l.exists?(:sqrtf)      .to_s
  puts 'libm has pow()? '         + l.exists?(:pow)        .to_s
  puts 'libm has not_in_libm()? ' + l.exists?(:not_in_libm).to_s

  puts 'sqrtf(36.f) = '    + l.call(:sqrtf, 'f)f', 36.0)      .to_s
  puts 'pow(2.0, 10.0) = ' + l.call(:pow,   'dd)d', 2.0, 10.0).to_s
end

