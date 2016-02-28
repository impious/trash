require 'escort'
require 'colorize'
require 'httpclient'


class Hfuzz < Escort::ActionCommand::Base
  def find
      #arguments
      file=command_options[:dic]
      url=command_options[:url]
      threads = []

      if File.exist?(file)
        puts ':: Found dictionary, checking urls'.green
        File.foreach( 'dic.txt' ) do |line|
          threads << Thread.new do
            httpclientbruteforce(url,line.chomp)
          end
        end
      else
        puts ':: Could not open file. Bad dir?'.red
      end

      threads.each do |thread|
        thread.join
      end
  end

  def httpclientbruteforce(url,line)
    clnt = HTTPClient.new
  #  puts url+'/'+line
    if clnt.get(url+'/'+line).status == 200 || clnt.get(url+'/'+line).status == 500 
      puts ":: Found url => #{url+'/'+line}".green
    end
  end

end

Escort::App.create do |app|
  app.version "0.1"
  app.summary "fuzzy directory search"
  app.description "use wfuzz.py (https://github.com/xmendez/wfuzz) for real stuff"

  #app.requires_arguments
  app.options do |opts|
    opts.opt :dic, "dic", :short => '-d', :long => '--dicionary', :type => :string, :default=>"dic.txt"
    opts.opt :url, "url", :short => '-u', :long => '--url', :type=> :string, :default=>'http://localhost:80'
  end

  app.action do |options, arguments|
    Hfuzz.new(options, arguments).find

  end
end
