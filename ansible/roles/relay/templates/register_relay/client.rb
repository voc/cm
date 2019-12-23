#!/usr/bin/env ruby
# encoding: utf-8

require 'json'
require 'base64'
require 'openssl'
require 'net/http'
require 'net/https'

# AES encryption helper
def encrypt(data, password)
  cipher = OpenSSL::Cipher.new('aes-256-cbc')
  cipher.encrypt # set cipher to be encryption mode
  cipher.key = Digest::SHA256.digest(password)
  iv = cipher.random_iv

  encrypted = ''
  encrypted << cipher.update(data)
  encrypted << cipher.final
  base64_data = Base64.encode64(encrypted).gsub(/\n/, '')

  {
    iv: iv.unpack('H*')[0],
    data: base64_data
  }.to_json
end

# Please change me…
uri            = URI('https://c3voc.de/relayregister/register')
api_key        = '{{ lookup("keepass", "ansible/relay-register/api_key.password") }}'
encryption_key = '{{ lookup("keepass", "ansible/relay-register/encryption_key.password") }}'

# Create some useful variables for encryption and communication
client         = Net::HTTP.new(uri.host, uri.port)
client.use_ssl = true
request        = Net::HTTP::Post.new(uri.path)

# Gather raw data from system
raw_data = {
  api_key: api_key,
  raw_data: {
    hostname: `hostname -f`,
    lspci: `lspci`,
    ip_config: `ip a`,
    disk_size: `df -h`,
    memory: `free -m`,
    cpu: File.read('/proc/cpuinfo')
  }
}.to_json

# Prepare request body
data = encrypt(raw_data, encryption_key)

# Send data to server
request.content_type = 'application/json'
request.body = data
response = client.request(request)

puts "http status: #{response.code}"
