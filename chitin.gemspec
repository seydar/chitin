$:.push File.expand_path("../lib", __FILE__)
require "chitin/version"

Gem::Specification.new do |s|
  # Metadata
  s.name        = "chitin"
  s.version     = Chitin::VERSION
  s.authors     = ["Ari Brown"]
  s.email       = ["ari@aribrown.com"]
  s.homepage    = "http://bitbucket.org/seydar/chitin"
  s.summary     = %q{A shell! In Ruby!}
  s.description = <<DESC
The point of Chitin is that you should be able to use Ruby in your shell. Bash
is too old. Time for the new wave of shell environments.
DESC

  s.rubyforge_project = "chitin"

  # Manifest
  s.files         = `hg manifest`.split("\n")
  s.executables   = ["chitin"]
  s.require_paths = ["lib"]

  # Dependencies
  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "wirble"
  s.add_runtime_dependency "coolline", ">= 0.4.0"
  s.add_runtime_dependency "coderay"
end

