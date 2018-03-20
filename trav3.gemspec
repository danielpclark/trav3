
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "trav3/version"

Gem::Specification.new do |spec|
  spec.name          = "trav3"
  spec.version       = Trav3::VERSION
  spec.authors       = ["Daniel P. Clark"]
  spec.email         = ["6ftdan@gmail.com"]

  spec.summary       = %q{Simple Travis V3 API Client}
  spec.description   = %q{A Simple client abstraction for the Travis V3 API}
  spec.homepage      = "https://github.com/danielpclark/trav3"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Generate YARD DOC on install
  spec.metadata["yard.run"] = "yri"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
