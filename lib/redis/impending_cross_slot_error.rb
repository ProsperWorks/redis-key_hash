# Raised from Redis::KeyHash.all_in_one_slot! on a mismatch.
#
# Generally, this indicates we were about to risk a Redis operation
# which is likely to produce a Redis error result like:
#
#  (error) CROSSSLOT Keys in request don't hash to the same slot
#
# TODO: rdoc
#
class Redis
  class ImpendingCrossSlotError < ArgumentError # TODO: Redis::CommandError?
    #
    # TODO: capture the problems with the keys?
    #
  end
end
