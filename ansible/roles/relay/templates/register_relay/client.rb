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
uri            = URI('http://c3voc.de/relayregister/register')
api_key        = '{{ lookup("keepass", "ansible/relay-register/33c3_api_key.password") }}'
encryption_key = '{{ lookup("keepass", "ansible/relay-register/33c3_encryption_key.password") }}'

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
