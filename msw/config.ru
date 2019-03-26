require 'rubygems'
require 'bundler'
# require 'timber'
Bundler.require

require './msw.rb'
run Sinatra::Application
