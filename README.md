# Listener

Postgres' LISTEN/NOTIFY system is awesome and all, but PG connections are expensive. Instead of establishing a new one for every place in your application that needs to LISTEN for something, use Listener.

## Installation

Add this line to your application's Gemfile:

    gem 'listener'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install listener

## Usage

``` ruby
pg = PG::Connection.open(...)

listener = Listener.new(pg)

listener.listen :channel1 do |channel, pid, payload|
  # This block will run on a NOTIFY to channel1.
  # The return value will be discarded, and errors it raises will be ignored.
  puts [channel, pid, payload].inspect
end

listener.listen :channel1, :channel2 do |channel, pid, payload|
  # This block will run on a NOTIFY to either channel1 OR channel2. When
  # channel1, it will run after the one above, since it was declared second.
end

# From another connection: NOTIFY channel1, 'payload string'

#=> ["channel1", 29923, "payload string"]

# Stop listening to all channels, and make the connection safe for other code to use:
listener.stop
```

### Caveats

1. It's up to you to make sure that no other threads try to use the PG connection that you pass to Listener. If you steal a connection from your ORM, make sure you've checked it out from the connection pool properly so that nothing else will try to use it.
2. Do **NOT** pass untrusted input as channel names. It is not currently escaped, since Postgres and/or the PG gem apparently don't support the use of placeholders in a LISTEN statement, so I'm using plain old string interpolation, which is an SQL injection risk. If anyone knows a way around this, please let me know.
3. Each listener you instantiate has a dedicated thread that runs all the blocks for all the notifications the connection receives. If you're not comfortable with multi-threading, you probably shouldn't be using this gem. Also, try to avoid doing anything time-consuming like I/O in your blocks - if you keep the listener thread busy, notifications may pile up and not be serviced in a timely manner. If you need to do something heavy duty, pass it off to another thread.

You can also pass options to Listener.new:
* **:timeout** is the amount of time passed to wait_for_notify each time the listener calls it. The default is 0.1, or 100 milliseconds. Higher values mean that there may be more of a delay before new blocks can be added or before the listener stops, while lower values may decrease efficiency by spending more time going back-and-forth with Postgres.
* **:priority** is the priority of the Listener thread - Ruby uses this to decide which threads get CPU time when there's not enough to go around. The default value is 1, which makes the Listener thread somewhat more important than your other Ruby threads (Ruby thread priority defaults to zero).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
