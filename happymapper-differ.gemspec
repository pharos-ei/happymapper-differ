# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'happymapper'
require 'happymapper_differ'

Gem::Specification.new do |spec|
  spec.name          = "happymapper-differ"
  spec.version       = HappyMapper::Differ::VERSION
  spec.authors       = ["John Weir"]
  spec.email         = ["john@smokinggun.com"]
  spec.summary       = %q{Find changes between two like HappyMapper objects}
  spec.description   = %q{
    In the unlikely event you are using HappyMapper, and the more unlikely
    event you need to find changes between two HappyMapper objects,
    HappyMapper::Differ might help you.

    HappyMapper::Differ takes two HappyMapper objects and compares all the
    attributes and elements.  It modfies each element to include if it has changed
    and what it changes are.
  }

  spec.homepage      = "https://github.com/pharos-ei/happymapper-differ"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri-happymapper", "~> 0.5"

  spec.add_development_dependency "byebug", "~> 3.5"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
