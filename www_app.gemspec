# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "www_app"
  spec.version       = `cat VERSION`
  spec.authors       = ["da99"]
  spec.email         = ["i-hate-spam-1234567@mailinator.com"]
  spec.summary       = %q{Ruby -> HTML/CSS/JS}
  spec.description   = %q{
    A DSL to create HTML/CSS/JS apps using Ruby.
  }
  spec.homepage      = "https://github.com/da99/www_app"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |file|
    file.index('bin/') == 0 && file != "bin/www_app"
  }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.2.0'

  spec.add_runtime_dependency "yajl-ruby"            , ">= 1.2"
  spec.add_runtime_dependency "escape_escape_escape" , ">= 0.2"
  spec.add_runtime_dependency "mustache"             , ">= 0.99"

  spec.add_development_dependency "multi_json"    , ">= 1.10.1"
  spec.add_development_dependency "sanitize"      , ">= 3.0.0"
  spec.add_development_dependency "pry"           , ">= 0.9"
  spec.add_development_dependency "bundler"       , ">= 1.5"
  spec.add_development_dependency "bacon"         , ">= 1.0"
  spec.add_development_dependency "Bacon_Colored" , ">= 0.1"
  spec.add_development_dependency "differ"        , ">= 0.1.2"
  spec.add_development_dependency "thin"          , ">= 1.6.2"
  spec.add_development_dependency "cuba"          , ">= 3.3.0"
  spec.add_development_dependency "da99_rack_protect", ">= 2.0.0"
end
