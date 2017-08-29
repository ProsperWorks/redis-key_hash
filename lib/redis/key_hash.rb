require 'redis/key_hash/version'
require 'redis/impending_cross_slot_error'

module Redis::KeyHash

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    # TODO: rubocop
    # TODO: rdoc

    # KNOWN_STYLES are the known reference styles.
    #
    KNOWN_STYLES   ||= {

      # The :style => :rc implementation matches Redis Cluster exactly
      # and is taken largely from the reference example provided in
      # http://redis.io/topics/cluster-spec.
      #
      :rc   => /^[^{]*{([^}]+)}/, # RC uses first {}-expr, but only if nonempty

      # The :style => :rlec implementation is partly speculative.  It
      # is mostly interpreted from the default RedisLabs Enterprise
      # Cluster documentation at
      # https://redislabs.com/redis-enterprise-documentation/concepts-architecture/architecture/database-clustering/,
      # plus our experience at ProsperWorks that, out of the box, RLEC
      # uses the *last* {}-expr, not the first as in RC, from :rc
      # (which we would not care about), they are also structually
      # different (which can cause bugs unless we take special care).
      # :rc uses the first {}-expr in the, :rlec uses the last
      # {}-expr.
      #
      :rlec => /.*\{(.*)\}.*/,    # RLEC default per docs, uses last {}-expr

    }.freeze

    # The default for all_in_one_slot? and all_in_one_slot! is
    # [:rc,:rlec] to encourage the of portable persistent hashing
    # schemes.
    #
    # A scheme which works with both side-steps a potential vendor
    # lock-in.
    #
    DEFAULT_STYLES ||= [ :rc, :rlec ].freeze

    # The default style for hash_tag and hash_slot is :rc because we
    # only know the hashing algorithm for Redis Cluster.
    #
    # We can guess that the hash for RedisLabs Enterprise Cluster is
    # similar, but it is not documented.
    #
    DEFAULT_STYLE  ||= :rc

    # Tests whether all of keys will hash to the same slot in all
    # specified sharding styles.
    #
    # @param keys String keys to be tested
    #
    # @param namespace String or nil if non-nil, applied as a prefix to
    # all keys as per the redis-namespace gem before testing.
    #
    # @param styles Array of Symbols and/or Regexps as per hash_tag().
    #
    # @return true if all of keys provably have the same hash_slot under
    # all styles by virtue of having a single hash_tag, false otherwise.
    #
    def all_in_one_slot?(*keys, namespace: nil, styles: DEFAULT_STYLES)
      begin
        all_in_one_slot!(*keys, namespace: namespace, styles: styles)
      rescue Redis::ImpendingCrossSlotError
        return false
      else
        return true
      end
    end

    # Like all_in_one_slot?, mismatch raises Redis::ImpendingCrossSlotError.
    #
    # @param keys String keys to be tested
    #
    # @param namespace String or nil if non-nil, applied as a prefix to
    # all keys as per the redis-namespace gem before testing.
    #
    # @param styles Array of Symbols and/or Regexps as per hash_tag().
    #
    # @return true if all of keys will hash to the same slot in all of
    # the styles, false if there is any doubt.
    #
    # @return true if all of keys provably have the same hash_slot
    # under all styles by virtue of having a single hash_tag.
    #
    # @raises Redis::ImpendingCrossSlotError if, for any styles, the
    # keys have a different hash_tag hence will not provably have the
    # same hash_slot
    #
    def all_in_one_slot!(*keys, namespace: nil, styles: DEFAULT_STYLES)
      nkeys       = namespace ? keys.map { |key| "#{namespace}:#{key}" } : keys
      style2slot  = Hash.new
      problems    = []
      styles.each do |style|
        tags      = nkeys.map { |nkey| hash_tag(nkey,style: style) }.uniq
        next if tags.size <= 1
        problems << "style #{style} sees tags #{tags.join(',')}"
      end
      if 0 != problems.size
        err  = "CROSSSLOT"
        err += " namespace=#{namespace}"
        err += " keys=#{keys}"
        err += " problems=#{problems}"
        raise Redis::ImpendingCrossSlotError, err
      end
      true
    end

    # Computes the hash tag for a given key under a given Redis
    # clustering algorithm.
    #
    # @param String key to be hashed
    #
    # @param Symbol :rc or rlec or Regexp which defines one capture group
    #
    # @param String the tag extracted from key as appropriate for :style.
    #
    def hash_tag(key, style: DEFAULT_STYLE)
      regexp = nil
      if KNOWN_STYLES.has_key?(style)
        regexp = KNOWN_STYLES[style] # some are predefined
      elsif style.is_a?(Regexp)
        regexp = style               # you can define your own
      end
      if !regexp
        raise ArgumentError, "bogus style #{style}"
      end
      match = regexp.match(key)
      return match ? match[1] : key
    end

    # Computes the Redis hash_slot for a given key.
    #
    # Uses :style as per hash_tag, but performs hashing as per RC
    # only.  We know through documentation and experimentation that RC
    # uses crc16() and modulo 16384.  We do not know what RLEC does,
    # but until we have a better model we assume it is the same.  This
    # is probably a false assumption since the RLEC docs state that
    # the number of shards can vary from cluster to cluster.  But for
    # many analyses, using the same hash as RC is still useful.
    #
    # @param String key to be hashed
    #
    # @param Symbol :rc or :rlec or Regexp which defines one capture group
    #
    # @param non-negative Integer the hash which Redis will use to slot key
    #
    def hash_slot(key, style: DEFAULT_STYLE)
      tag = hash_tag(key, style: style)
      crc16(tag) % 16384
    end

    # Computes the Redis crc16 for a given key, as per the reference
    # implementation provided in http://redis.io/topics/cluster-spec.
    #
    # This implementation is taken largely from that reference document,
    # changed only slightly to port to Ruby.
    #
    # @param String key
    #
    # @param non-negative Integer the crc16 which Redis will use to
    # compute a hash_key.
    #
    def crc16(key)
      crc = 0
      key.each_char do |char|
        crc = ((crc << 8) & 0xFFFF) ^ CRC16TAB[((crc >> 8) ^ char.ord) & 0x00FF]
      end
      crc
    end

    CRC16TAB ||= [
      0x0000,0x1021,0x2042,0x3063,0x4084,0x50a5,0x60c6,0x70e7,
      0x8108,0x9129,0xa14a,0xb16b,0xc18c,0xd1ad,0xe1ce,0xf1ef,
      0x1231,0x0210,0x3273,0x2252,0x52b5,0x4294,0x72f7,0x62d6,
      0x9339,0x8318,0xb37b,0xa35a,0xd3bd,0xc39c,0xf3ff,0xe3de,
      0x2462,0x3443,0x0420,0x1401,0x64e6,0x74c7,0x44a4,0x5485,
      0xa56a,0xb54b,0x8528,0x9509,0xe5ee,0xf5cf,0xc5ac,0xd58d,
      0x3653,0x2672,0x1611,0x0630,0x76d7,0x66f6,0x5695,0x46b4,
      0xb75b,0xa77a,0x9719,0x8738,0xf7df,0xe7fe,0xd79d,0xc7bc,
      0x48c4,0x58e5,0x6886,0x78a7,0x0840,0x1861,0x2802,0x3823,
      0xc9cc,0xd9ed,0xe98e,0xf9af,0x8948,0x9969,0xa90a,0xb92b,
      0x5af5,0x4ad4,0x7ab7,0x6a96,0x1a71,0x0a50,0x3a33,0x2a12,
      0xdbfd,0xcbdc,0xfbbf,0xeb9e,0x9b79,0x8b58,0xbb3b,0xab1a,
      0x6ca6,0x7c87,0x4ce4,0x5cc5,0x2c22,0x3c03,0x0c60,0x1c41,
      0xedae,0xfd8f,0xcdec,0xddcd,0xad2a,0xbd0b,0x8d68,0x9d49,
      0x7e97,0x6eb6,0x5ed5,0x4ef4,0x3e13,0x2e32,0x1e51,0x0e70,
      0xff9f,0xefbe,0xdfdd,0xcffc,0xbf1b,0xaf3a,0x9f59,0x8f78,
      0x9188,0x81a9,0xb1ca,0xa1eb,0xd10c,0xc12d,0xf14e,0xe16f,
      0x1080,0x00a1,0x30c2,0x20e3,0x5004,0x4025,0x7046,0x6067,
      0x83b9,0x9398,0xa3fb,0xb3da,0xc33d,0xd31c,0xe37f,0xf35e,
      0x02b1,0x1290,0x22f3,0x32d2,0x4235,0x5214,0x6277,0x7256,
      0xb5ea,0xa5cb,0x95a8,0x8589,0xf56e,0xe54f,0xd52c,0xc50d,
      0x34e2,0x24c3,0x14a0,0x0481,0x7466,0x6447,0x5424,0x4405,
      0xa7db,0xb7fa,0x8799,0x97b8,0xe75f,0xf77e,0xc71d,0xd73c,
      0x26d3,0x36f2,0x0691,0x16b0,0x6657,0x7676,0x4615,0x5634,
      0xd94c,0xc96d,0xf90e,0xe92f,0x99c8,0x89e9,0xb98a,0xa9ab,
      0x5844,0x4865,0x7806,0x6827,0x18c0,0x08e1,0x3882,0x28a3,
      0xcb7d,0xdb5c,0xeb3f,0xfb1e,0x8bf9,0x9bd8,0xabbb,0xbb9a,
      0x4a75,0x5a54,0x6a37,0x7a16,0x0af1,0x1ad0,0x2ab3,0x3a92,
      0xfd2e,0xed0f,0xdd6c,0xcd4d,0xbdaa,0xad8b,0x9de8,0x8dc9,
      0x7c26,0x6c07,0x5c64,0x4c45,0x3ca2,0x2c83,0x1ce0,0x0cc1,
      0xef1f,0xff3e,0xcf5d,0xdf7c,0xaf9b,0xbfba,0x8fd9,0x9ff8,
      0x6e17,0x7e36,0x4e55,0x5e74,0x2e93,0x3eb2,0x0ed1,0x1ef0
    ].freeze

  end

end
