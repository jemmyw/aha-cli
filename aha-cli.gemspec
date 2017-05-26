Gem::Specification.new do |spec|
  spec.name  = "aha-cli"
  spec.version = "0.0.1"
  spec.authors = ["Jeremy Wells"]
  spec.email = ["jemmyw@gmail.com"]
  spec.summary = "Aha! Cli"
  spec.description = "Access aha.io API from the command line"

  spec.add_dependency "addressable"
  spec.add_dependency "rake"
  spec.add_dependency "thor"
  spec.add_dependency "faraday", "~> 0.12.1"
  spec.add_dependency "faraday_middleware"
end