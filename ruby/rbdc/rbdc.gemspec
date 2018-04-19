#//////////////////////////////////////////////////////////////////////
#
# rbdc.gemspec
# Copyright (c) 2007-2015 Daniel Adler <dadler@uni-goettingen.de>, 
#                         Tassilo Philipp <tphilipp@potion-studios.com>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Ruby gems specification file.
#
#///////////////////////////////////////////////////////////////////////

require 'rake'
#dyncall_dir = ENV['DC_DIR']
#FileUtils.symlink dyncall_dir, 'dyncall'#, :force => true

Gem::Specification.new do |spec|
	spec.name                  = 'rbdc'
	spec.author                = 'Tassilo Philipp'
	spec.email                 = 'tphilipp@potion-studios.com'
	spec.homepage              = 'http://www.dyncall.org'

	spec.summary               = 'foreign function interface for C calls'
	spec.description           = 'Ruby interface to dyncall, allowing programmers to call C functions in shared libraries from ruby without writing any glue code at all (e.g. "l.load(\'/usr/lib/libm.so\'); puts \'pow(2.0, 10.0) = \' + l.call(:pow, \'dd)d\', 2.0, 10.0).to_s")'

	spec.version               = '1.0.0'
	spec.required_ruby_version = '>= 1.9.1'
	spec.license               = 'ISC'

	# Note that this requires dyncall to live in this directory, create a symlink to the dyncall directory.
	spec.files                 = FileList['dyncall/**/*', 'rbdc.c'].exclude('dyncall/doc/**/*').exclude('dyncall/test/**/*').to_a
	spec.extensions            << 'extconf.rb'
end

