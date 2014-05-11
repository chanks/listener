require 'spec_helper'

describe Listener do
  it "should allow a block to be assigned to run when a notification is received on a channel" do
    q = Queue.new
    l = Listener.new($conn1, timeout: 0.001)
    l.listen('my_channel') { |*output| q.push output }

    pid = $conn2.async_exec("select pg_backend_pid()").first['pg_backend_pid']
    $conn2.async_exec("notify my_channel, 'my_payload'")

    q.pop.should == ['my_channel', pid.to_i, 'my_payload']
    l.stop
  end

  it "should allow the same block to be assigned for multiple channels" do
    q = Queue.new
    l = Listener.new($conn1, timeout: 0.001)
    l.listen('channel1', 'channel2') { |channel, pid, payload| q.push channel }

    %w(channel1 channel2 channel1).each { |c| $conn2.async_exec("notify #{c}") }

    3.times.map{q.pop}.should == %w(channel1 channel2 channel1)
    l.stop
  end

  it "should allow multiple blocks to be assigned for the same channel" do
    q = Queue.new
    l = Listener.new($conn1, timeout: 0.001)
    l.listen('my_channel') { q.push 1 }
    l.listen('my_channel') { q.push 2 }

    2.times { $conn2.async_exec("notify my_channel") }

    4.times.map{q.pop}.should == [1, 2, 1, 2]
    l.stop
  end

  it "should accept symbols as channel names" do
    q = Queue.new
    l = Listener.new($conn1, timeout: 0.001)
    l.listen(:my_channel) { q.push 1 }
    l.listen(:my_channel) { q.push 2 }

    2.times { $conn2.async_exec("notify my_channel") }

    4.times.map{q.pop}.should == [1, 2, 1, 2]
    l.stop
  end

  it "should recover from errors in blocks" do
    q = Queue.new
    l = Listener.new($conn1, timeout: 0.001)
    l.listen('my_channel') { raise }
    l.listen('my_channel') { q.push 1 }

    2.times { $conn2.async_exec("notify my_channel") }

    2.times.map{q.pop}.should == [1, 1]
    l.stop
  end

  it "when told to stop should unlisten to all channels and drain existing notifications before returning" do
    q1, q2 = Queue.new, Queue.new
    l = Listener.new($conn1, timeout: 0.001)
    l.listen('my_channel') { q1.push nil; q2.pop }

    2.times { $conn2.async_exec("notify my_channel") }
    q1.pop

    t = Thread.new { l.stop }
    $conn2.async_exec("notify my_channel")
    q2.push nil
    t.join

    $conn1.async_exec("select pg_listening_channels()").to_a.length.should == 0
    $conn1.wait_for_notify(0.001).should be nil
  end
end
