# Redis::KeyHash

Tests of key hash slot agreement for use with Redis Cluster and
RedisLabs Enterprise Cluster.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis-key_hash'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis-key_hash

## Usage

    require 'redis/key_hash'
    
    # As syntactic sugar, expose Redis::KeyHash methods in the Redis class.
    #
    Redis.include Redis::KeyHash
    
    # Test whether several keys will hash to the same slot.
    #
    if Redis.all_in_one_slot?('a','b')
      'happy'
    else
      'sad'
    end
    Redis.all_in_one_slot!('a','b') # may raise Redis::ImpendingCrossSlotError

## Development

After checking out the repo, run `bin/setup` to install
dependencies. Then, run `rake test` to run the tests. You can also run
`bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake
install`. To release a new version, update the version number in
`version.rb`, and then run `bundle exec rake release`, which will
create a git tag for the version, push git commits and tags, and push
the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/ProsperWorks/redis-key_hash.

