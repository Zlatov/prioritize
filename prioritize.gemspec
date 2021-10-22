require_relative 'lib/prioritize/version'

Gem::Specification.new do |spec|
  spec.name          = "prioritize"
  spec.version       = Prioritize::VERSION
  spec.authors       = ["Zlatov"]
  spec.email         = ["zlatov@ya.ru"]

  spec.summary       = "Prioritize a ActiveRecord list"
  spec.description   = "Adds a method that allows you to update the model column used for sorting."
  spec.homepage      = "https://github.com/Zlatov/prioritize"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Zlatov/prioritize.git"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "activerecord", '~> 5.0', '>= 5.0.0.1'
end
