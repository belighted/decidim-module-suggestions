# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/suggestions/version"

Gem::Specification.new do |s|
  s.version = Decidim::Suggestions.version
  s.authors = ["Belighted"]
  s.email = ["be@belighted.com"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/belighted/decidim-module-suggestions"
  s.required_ruby_version = ">= 2.6"

  s.name = "decidim-suggestions"
  s.summary = "Decidim suggestions module"
  s.description = "Citizen suggestions plugin for decidim."

  s.files = Dir["{app,config,db,lib,vendor}/**/*", "Rakefile", "README.md"]

  s.add_dependency "decidim-admin", Decidim::Suggestions.version
  s.add_dependency "decidim-comments", Decidim::Suggestions.version
  s.add_dependency "decidim-core", Decidim::Suggestions.version
  s.add_dependency "decidim-verifications", Decidim::Suggestions.version
  s.add_dependency "kaminari", "~> 1.2", ">= 1.2.1"
  s.add_dependency "origami", "~> 2.1"
  s.add_dependency "virtus-multiparams", "~> 0.1"
  s.add_dependency "wicked", "~> 1.3"
  s.add_dependency "wicked_pdf", "~> 1.4"
  s.add_dependency "wkhtmltopdf-binary", "~> 0.12"

  s.add_development_dependency "decidim-dev", Decidim::Suggestions.version
end