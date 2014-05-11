require 'uri'
require 'pg'
require 'listener'
require 'pry'
require 'thread'

url = ENV['DATABASE_URL'] || 'postgres://postgres:@localhost/listener-test'

$conn1, $conn2 = 2.times.map do
  uri = URI.parse(url)
  PG::Connection.open :host     => uri.host,
                      :user     => uri.user,
                      :password => uri.password,
                      :port     => uri.port || 5432,
                      :dbname   => uri.path[1..-1]
end
