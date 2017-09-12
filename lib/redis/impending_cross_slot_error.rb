class Redis

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
  class ImpendingCrossSlotError < ArgumentError # TODO: Redis::CommandError?

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
