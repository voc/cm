# encoding: utf-8

require 'json'
require 'base64'
require 'openssl'
require 'net/http'

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
uri            = URI('http://c3voc.de/31c3/register/register')
api_key        = '70fb66b9efefb7ccb6084d217569694fd1624fa8883660204517bb9b532251e53cfa5bb2f55791f02257b3be3a9ccc533e1b5b8e9b580810771223c9aa9632bd'
encryption_key = 'Shop&Fringe8Fury'

# Create some useful variables for encryption and communication
iv             = OpenSSL::Cipher.new('aes-256-cbc').random_iv.unpack('H*')[0]
client         = Net::HTTP.new(uri.host, uri.port)
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
data = {
  iv: iv,
  data: encrypt(raw_data, encryption_key, iv)
}.to_json

# Send data to server
request.content_type = 'application/json'
request.body = data
response = client.request(request)

puts "http status: #{response.code}"
