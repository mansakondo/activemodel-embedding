require_relative "lib/active_model/embedding/version"

Gem::Specification.new do |spec|
  spec.name        = "activemodel-embedding"
  spec.version     = ActiveModel::Embedding::VERSION
  spec.authors     = ["mansakondo"]
  spec.email       = ["mansakondo22@gmail.com"]
  spec.homepage    = "https://github.com/mansakondo/activemodel-embedding"
  spec.summary     = "Embedded associations for your semi-structured data"
  spec.description = "An ActiveModel extension to model your semi-structured data using embedded associations"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/mansakondo/activemodel-embedding/blob/main/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "rails", ">= 6.1.4"
end
