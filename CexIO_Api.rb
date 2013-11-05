=begin
/*

The MIT License (MIT)

Copyright (c) 2013 Zhussupov Zhassulan zhzhussupovkz@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/
=end

require 'net/http'
require 'net/https'
require 'json'
require 'openssl'
require 'base64'

class CexIO_Api

  def initialize api_key, secret, username
    @api_url = 'https://cex.io/api/'
    @api_key, @secret, @username = api_key, secret, username
  end

  #send public request to the server
  def public_request method, params = {}
    params = URI.escape(params.collect{ |k,v| "#{k}=#{v}"}.join('&'))
    url = @api_url + method + '?' + params
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(uri.path)
    res = http.request(req)
    data = res.body
    result = JSON.parse(data)
  end

  #send private request to the server
  def private_request method, params = {}
    nonce = Time.now.to_i.to_s
    message = nonce.to_s + @username + @api_key
    sha256 = OpenSSL::Digest::SHA256.new
    hash = OpenSSL::HMAC.digest(sha256, @secret, message)
    signature = Base64.encode64(hash).chomp.gsub( /\n/, '' )
    required = { 'key' => @api_key, 'nonce' => nonce, 'signature' => signature }
    params = required.merge(params)
    uri = URI.parse(@api_url + method)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    req.body = params.to_json
    res = http.request(req)
    data = res.body
    result = JSON.parse(data)
  end

  #################################### PUBLIC ###################################
  ############### ticker ####################
  #Returns JSON dictionary:
    #last - last BTC price
    #high - last 24 hours price high
    #low - last 24 hours price low
    #volume - last 24 hours volume
    #bid - highest buy order
    #ask - lowest sell order
  def ticker
    public_request 'ticker/GHS/BTC'
  end

  ############### order_book ###############
  #Returns JSON dictionary with "bids" and "asks". 
  #Each is a list of open orders and each order is 
  #represented as a list of price and amount.
  def order_book
    public_request 'order_book/GHS/BTC'
  end

  ############### trade_history ###############
  #Returns a list of recent trades, where each trade is a JSON dictionary:
    #tid - trade id
    #amount - trade amount
    #price - price
    #date - UNIX timestamp
  def trade_history params = {}
    public_request 'trade_history/GHS/BTC', params
  end

  #################################### PRIVATE ###################################
  ############## balance ################
  #Returns JSON dictionary:
    #available - available balance
    #orders - balance in pending orders
    #bonus - referral program bonus
  def balance
    private_request 'balance'
  end

  ############## open orders #############
  #Returns JSON list of open orders. Each order is represented as dictionary:
    #id - order id
    #time - timestamp
    #type - buy or sell
    #price - price
    #amount - amount
    #pending - pending amount (if partially executed)
  def open_orders
    private_request 'open_orders/GHS/BTC'
  end

  ############## cancel order ############
  #Returns 'true' if order has been found and canceled.
  #Params:
    #id - order ID
  def cancel_order order_id
    nonce = Time.now.to_i
    message = nonce.to_s + @username + @api_key
    sha256 = OpenSSL::Digest::SHA256.new
    hash = OpenSSL::HMAC.digest(sha256, @secret, message)
    signature = Base64.encode64(hash)
    params = { 'key' => @api_key, 'nonce' => nonce, 'signature' => signature, 'id' => order_id }
    uri = URI.parse(@api_url + 'cancel_order')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    req.body = params.to_json
    res = http.request(req)
    data = res.body
    result = JSON.parse(data)
  end

  ############ place order #############
  #Returns JSON dictionary representing order:
    #id - order id
    #time - timestamp
    #type - buy or sell
    #price - price
    #amount - amount
    #pending - pending amount (if partially executed)
  #Params:
    #type - 'buy' or 'sell'
    #amount - amount
    #price - price
  def place_order params
    false if !params.key? 'type'
    private_request 'place_order/GHS/BTC', params
  end

end
