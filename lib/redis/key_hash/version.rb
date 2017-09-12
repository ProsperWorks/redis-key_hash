class Redis
  module KeyHash
    #
    # Version plan/history:
    #
    # 0.0.1 - Still in Prosperworks/ALI/vendor/gems/redis-key_hash.
    #
    # 0.0.2 - Broke out into Prosperworks/redis-key_hash, make public.
    #
    # 0.0.3 - Fix :rc to match https://redis.io/topics/cluster-spec,
    #         added Rubocop checks.
    #
    # 0.0.4 - Bug fixes around namespace, more details in
    #         Redis::ImpendingCrossSlotError, Rubocop polish and
    #         defiance.
    #
    # 0.1.0 - (future) Big README.md and Rdoc update, solicit feedback
    #         from select external beta users.
    #
    # 0.2.0 - (future) Incorporate feedback, announce.
    #
    VERSION = '0.0.4'.freeze
  end
end
