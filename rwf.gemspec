# frozen_string_literal: true

require_relative 'lib/rwf/version'

Gem::Specification.new do |s|
  s.name = 'rwf'
  s.version = RWF::Version::STRING
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.1.0'
  s.authors = ['balbesina']
  s.description = <<-DESCRIPTION
    description
  DESCRIPTION

  s.email = 'megabalbes@gmail.com'
  s.licenses = ['MIT']
  s.homepage = 'https://github.com/balbesina/rwf'
  s.files = `git ls-files`.split($RS)
  s.summary = 'summary'
end
