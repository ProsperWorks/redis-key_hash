
class Redis

  # Forward declarations of Redis package errors so we can declare
  # them as the parent of Redis::ImpendingCrossSlotError without
  # taking a hard development or runtime dependency on the gem
  # 'redis'.
  #
  # There remains an implicit dependency that later, when the 'redis'
  # gem is loaded by the app, these declarations are consistent with
  # those in the gem.
  #
  class BaseError < RuntimeError
  end
  class CommandError < BaseError
  end

  # Captures the details from a potential CROSSSLOT error as
  # identified by Redis::KeyHash.all_in_one_slot!.
  #
  # Generally, this indicates we were about to risk a Redis operation
  # which is likely to produce a Redis error result like:
  #
  #  (error) CROSSSLOT Keys in request don't hash to the same slot
  #
  # TODO: rdoc
  #
  # Redis::ImpendingCrossSlotError is a Redis::CommandError because
  # the intention is to use Redis::KeyHash.all_in_one_slot! as a
  # filter in front of Redis#eval, which will raise a
  # Redis::CommandError when redis-server returns a CROSSSLOT error.
  #
  class ImpendingCrossSlotError < CommandError

    def initialize(namespace,keys,namespaced_keys,problems)
      err  = "CROSSSLOT"
      err += " namespace=#{namespace.inspect}"
      err += " keys=#{keys.inspect}"
      err += " namespaced_keys=#{namespaced_keys.inspect}"
      err += " problems=#{problems.inspect}"
      super(err)
      @namespace       = namespace ? namespace.dup.freeze : nil
      @keys            = keys.dup.freeze
      @namespaced_keys = namespaced_keys.dup.freeze
      @problems        = problems.dup.freeze
    end

    attr_accessor :namespace
    attr_accessor :keys
    attr_accessor :namespaced_keys
    attr_accessor :problems

  end

end
