# encoding: utf-8

require 'json'
require 'base64'
require 'openssl'
require 'net/http'
require 'thread'
require 'ipaddr'

# AES encryption helper
def encrypt(data, password, iv)
  cipher = OpenSSL::Cipher.new('aes-256-cbc')
  cipher.encrypt # set cipher to be encryption mode
  cipher.key = Digest::SHA256.digest(password)
  cipher.iv = iv

  encrypted = ''
  encrypted << cipher.update(data)
  encrypted << cipher.final
  Base64.encode64(encrypted).gsub(/\n/, '')
end

# Please change me…
uri            = URI('http://c3voc.de/31c3/register/register/bandwith')
api_key        = '70fb66b9efefb7ccb6084d217569694fd1624fa8883660204517bb9b532251e53cfa5bb2f55791f02257b3be3a9ccc533e1b5b8e9b580810771223c9aa9632bd'
encryption_key = 'Shop&Fringe8Fury'

# Create some useful variables for encryption and communication
iv             = OpenSSL::Cipher.new('aes-256-cbc').random_iv.unpack('H*')[0]
client         = Net::HTTP.new(uri.host, uri.port)
request        = Net::HTTP::Post.new(uri.path)

# Define some funcations

# Run iperf command for given destination host.
#
# @param host [String] iperf destination host
# @return [String] iperf result in CSV format
def iperf(host)
  address = IPAddr.new(host)
  iperf = "iperf -c #{address} -r -y C"
  iperf += " -V" if address.ipv6?

  `#{iperf}`
end

def measure_iperf_data
  data = {}

  ARGV.each do |host|
    data[host] = iperf(host)
  end

  data
end

def deq(q)
  data = []

  until(q.empty?) do
    data << q.pop(true)
  end

  data.join
end

def measure_multiple_destinations
  queue   = Queue.new
  threads = []

  ARGV.each do |host|
    threads << Thread.new do
      data = iperf(host)
      queue.push(data)
    end
  end

  threads.map(&:join)
  deq(queue)
end

# Basic opt parsing and dependency checks
if `which iperf` == ''
  puts "You have to install iperf first."
  exit 1
elsif ARGV.length == 0
  puts "Start iperf on endpoints: `iperf -s`\n\n"
  puts "Run: #{$0} 10.10.13.37 192.23.24.2"
  exit 2
end

# Gather raw data from system
raw_data = {
  api_key: api_key,
  raw_data: {
    time: Time.now.to_i,
    ip_config: `ip a`,
    measures: {
      single_destinations: measure_iperf_data,
      multiple_destinations: {
        destinations: ARGV,
        iperf: measure_multiple_destinations,
      }
    }
  }
}.to_json

# Prepare request body
data = {
  iv: iv,
  data: encrypt(raw_data, encryption_key, iv)
}.to_json

# Send data to server
request.content_type = 'application/json'
request.body = data
response = client.request(request)

puts "http status: #{response.code}"
