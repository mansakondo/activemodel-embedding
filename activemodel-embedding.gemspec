require_relative "lib/active_model/embedding/version"

Gem::Specification.new do |spec|
  spec.name        = "activemodel-embedding"
  spec.version     = ActiveModel::Embedding::VERSION
  spec.authors     = ["mansakondo"]
  spec.email       = ["mansakondo22@gmail.com"]
  spec.homepage    = "https://github.com/mansakondo/activemodel-embedding"
  spec.summary     = "An ActiveModel extension to model your semi-structured data using embedded associations"
  spec.description = "An ActiveModel extension to model your semi-structured data using embedded associations"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/mansakondo/polymorphic_aliases/blob/main/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.4", ">= 6.1.4.1"
end
