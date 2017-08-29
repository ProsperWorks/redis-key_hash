lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis/key_hash/version'

Gem::Specification.new do |spec|
  spec.name          = "redis-key_hash"
  spec.version       = Redis::KeyHash::VERSION
  spec.authors       = ["jhwillett"]
  spec.email         = ["jhw@prosperworks.com"]
  spec.license       = 'MIT'

  spec.summary       = 'Tests Redis Cluster key hash slot agreement'
  spec.homepage      = 'https://github.com/ProsperWorks/redis-key_hash'
  spec.description   = %{
redis-key_hash provides tests of key hash slot agreement for use with
Redis Cluster and RedisLabs Enterprise Cluster.
}

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  # We use "foo: bar" syntax liberally, not the older ":foo => bar".
  # Possibly other Ruby 2-isms as well.
  #
  spec.required_ruby_version = '~> 2.0'

  spec.add_development_dependency "bundler",  "~> 1.14"
  spec.add_development_dependency "rake",     "~> 10.5"
  spec.add_development_dependency "minitest", "~> 5.10"

  # This gem is pure Ruby, no weird dependencies.
  #
  spec.platform = Gem::Platform::RUBY
end
