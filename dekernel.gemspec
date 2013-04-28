Gem::Specification.new do |s|
  s.name        = 'dekernel'
  s.version     = '0.0.0'
  s.date        = '2013-04-27'
  s.summary     = 'Remove old/unused kernel packages.'
  s.description = 'A simple tool to help with removing old/unused kernel packages using apt-get.'
  s.author      = 'david amick'
  s.email       = 'github@davidamick.com'
  s.homepage    = 'http://rubygems.org/gems/dekernel'
  s.default_executable = 'dekernel'
  s.require_paths = ['lib', 'lib/dekernel']
  s.files       = ['bin/dekernel']
  s.files      += ['lib/dekernel.rb']
  s.files      += ['lib/dekernel/cernel.rb']
  s.files      += ['lib/dekernel/message.rb']
  s.test_files  = ['spec/spec_helper.rb']
  s.test_files += ['spec/lib/dekernel_spec.rb']
  s.test_files += ['spec/lib/dekernel/cernel_spec.rb']
  s.test_files += ['spec/lib/dekernel/message_spec.rb']
  s.add_development_dependency 'rspec', ['~> 2.11']
end
