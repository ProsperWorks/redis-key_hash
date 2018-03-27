# 0.0.5 (2018-03-26)
- Expanded .travis.yml to cover more rvm versions.
- Shrink Rubocop coverage to exclude `Style/*`.
- Moves version history out into CHANGELOG.md.

# 0.0.4 (2017-09-12)
- Verified existing behavior w/r/t Redis::Namespace.
- Added more details in Redis::ImpendingCrossSlotError.
- Rubocop polish and defiance.
- Redis::KeyHash::ClassMethods inner-inner class removed.
- Redis::KeyHash changed to a class, not a module.
- Redis::ImpendingCrossSlotError changed from ArgumentError to Redis::RuntimeError.

# 0.0.3 (2017-08-29)

- Fix :rc to match https://redis.io/topics/cluster-spec, added Rubocop checks.

# 0.0.2 (2017-08-28)

- Broke out into Prosperworks/redis-key_hash, make public.

# 0.0.1 (prehistory)

- Still in Prosperworks/ALI/vendor/gems/redis-key_hash.

