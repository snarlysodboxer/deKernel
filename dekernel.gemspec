Gem::Specification.new do |s|
  s.platform            = Gem::Platform::RUBY
  s.name                = 'dekernel'
  s.version             = '0.0.1'
  s.date                = '2013-04-27'
  s.summary             = 'Remove old/unused kernel packages.'
  s.description         = 'deKernel is a simple tool that finds installed kernels and automates the removal of any you choose, freeing disk space. With optional flags, it can also be automated for scripting.'
  s.author              = 'david amick'
  s.email               = 'github@davidamick.com'
  s.homepage            = 'https://github.com/snarlysodboxer/deKernel#dekernel'
  s.executable          = 'dekernel'
  s.bindir              = 'bin'
  s.require_path        = 'lib'
  s.files               = ['bin/dekernel']
  s.files              += ['lib/dekernel.rb']
  s.files              += ['lib/dekernel/cernel.rb']
  s.files              += ['lib/dekernel/message.rb']
  s.test_files          = ['spec/spec_helper.rb']
  s.test_files         += ['spec/lib/dekernel_spec.rb']
  s.test_files         += ['spec/lib/dekernel/cernel_spec.rb']
  s.test_files         += ['spec/lib/dekernel/message_spec.rb']
  s.add_development_dependency 'rspec', ['~> 2.11']
end
