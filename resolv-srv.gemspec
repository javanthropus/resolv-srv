# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = 'resolv-srv'
  s.version     = '0.0.1'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Jeremy Bopp']
  s.email       = ['jeremy@bopp.net']
  s.homepage    = 'https://github.com/javanthropus/resolv-srv'
  s.license     = 'MIT'
  s.summary     = 'Resolve and iterate over SRV DNS records correctly.'
  s.description = <<-EOD
This gem patches the Resolv::DNS class in stdlib to include a method to resolve
and iterate over SRV records according to their relative priorities and weights.
  EOD

  s.add_development_dependency('rake', '~> 10.1', '> 10.1.1')
  s.add_development_dependency('minitest', '~> 5.3', '> 5.3.1')
  s.add_development_dependency('yard', '~> 0.8.7', '> 0.8.7.3')
  s.add_development_dependency('redcarpet', '~> 3.1', '> 3.1.0')
  s.add_development_dependency('github-markup', '~> 1.0', '> 1.0.2')
  s.add_development_dependency('pry', '~> 0')

  # Explicitly list all non-test files that should be included into the gem
  # here.  This and the test_files list will be compared against an
  # automatically generated list by rake to identify files potentially missed by
  # inclusion or exclusion rules.
  s.files        = %w(
    .yardopts
    LICENSE
    NEWS.md
    Rakefile
    README.md
    examples/active-directory.rb
    lib/resolv-srv.rb
  )
  # Explicitly list all test files that should be included into the gem here.
  s.test_files   = %w(
    spec/each_srv_resource_spec.rb
  )

  s.require_path = 'lib'
end
