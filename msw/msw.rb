# require 'bundler/setup'
require 'sinatra'
require 'omniauth-google-oauth2'
require 'mongoid'
require 'colorize'
require 'bson'
require 'feedjira'
require 'feedbag'
require 'sinatra/flash'
require 'csv'
require 'sanitize'
# require 'mongoid_fulltext'
require 'chartkick'
# require 'timber'
require 'mongoid_search'
require 'http'

configure do
  enable :sessions
end

# models

require File.expand_path('../model.rb', __FILE__)

#
# for dev
# export RACK_ENV=:development
 
if ENV['RACK_ENV'] == ':development'
  set :port, 3000
  Mongoid.load!("./mongoid.yml", :development)
  # config = YAML::load_file("database.yml")["development"]
end

if ENV['RACK_ENV'] == 'production'
  Mongoid.load!("./mongoid.yml", :production)
end

=begin

    global vars

=end

use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE1'],ENV['GOOGLE2']
end

=begin

  Helpers
  
=end

helpers do
  def logged_in?
    !session[:user_id].nil?
  end

  def current_user
    @current_user ||= User.get_user(session[:user_id]) if session[:user_id]
  end
end

=begin

  Code

=end

get '/auth/:provider/callback' do
  auth = env["omniauth.auth"]
  session[:user_id] = auth["uid"]
  session[:name] = auth["info"]["name"]
  user = User.from_omniauth(auth)
  redirect '/feeds'
end

get '/signout' do
  session[:user_id] = nil
  redirect '/'
end

get '/auth/failure' do
  redirect '/'
end

get '/' do
  if !logged_in?
    erb :index, :layout => false
  else
    redirect '/feeds'
  end
end

get '/feeds' do
  if current_user.nil?
    redirect '/'
  end
  # gets all user feeds & gets array of feeds
  @feeds = current_user.feeds.all
  arr = []
  threads = []
  for feed in @feeds
    threads << Thread.new(feed.url_rss) do |my_feed|
      begin
        result = Feedjira::Feed.fetch_and_parse my_feed
        arr.push(result)
      rescue Exception => e
        logger.error e
      end
    end
  end
  threads.each { |a_thread| a_thread.join }

  # we must order and ignore later than 7 days.
  @items = Hash.new

  arr.each do |url_feed|
    feed_name = url_feed.title  
    url_feed.entries.each do |entry|
      if entry.published >= Date.today - 7

        @items[entry.published.to_i] = { :title => entry.title,
                    :url => entry.url,
                    :published => entry.published.to_i,
                    :my_published=>entry.published.to_date,
                    :author =>entry.author,
                    :summary=>entry.summary,
                    :feed_name=>feed_name}
      end
    end
  end
  puts "WTF 2"

  @items = @items.sort_by { |_, value| -value[:published] }
  erb :feeds
end

get '/faqs' do
  erb :faq, :layout => true
end

get '/manage' do
  if current_user.nil?
    redirect '/'
  end
  @feeds = current_user.feeds.all
  erb :manage, :layout=>true
end

delete '/manage/:id' do
  if current_user.nil?
    redirect '/'
  end
  @feeds = current_user.feeds.all.find(params[:id]).delete
  redirect to('/manage')
end

get '/new' do
  if current_user.nil?
    redirect '/'
  end
  erb :new, :layout => true
end

get '/search' do
  if current_user.nil?
    redirect '/'
  end
  # results = current_user.feeds.fulltext_search('python')

  # puts "####"
  # puts results
  return erb :search, :layout => true
end

post '/search' do
  if current_user.nil?
    redirect '/'
  end

  value = Sanitize.clean(params[:search_value]).strip
  puts "Searching for #{value}".red
  @results = current_user.posts.full_text_search(value)
  # puts @results.size()
  # puts "erm".red
  # @results=Post.full_text_search(value)
  # puts @results
  # puts "end"

  # puts "RESULTS"
  # puts @results
  return erb :search
end

get '/to_csv' do
  if current_user.nil?
    redirect '/'
  end
  @feeds = current_user.feeds.all
  CSV.open('feeds.csv', 'w') do |csv|
      # for feed in @feeds
      @feeds.each do |feed|
        csv << [feed.name, feed.url, feed.url_rss]
    end
  end
  file = File.join('.', 'feeds.csv')
  send_file(file, :disposition => 'attachment', :filename => File.basename(file))
end

get '/save_post' do
  if current_user.nil?
    redirect '/'
  end

  @name = Sanitize.clean(params[:name]).strip
  @url = Sanitize.clean(params[:url]).strip
  @feed_name = Sanitize.clean(params[:feed_name]).strip

  @post = Post.new
  @post.url = @url
  @post.name = @name
  @post.feed_name = @feed_name

  x = current_user.posts.push(@post)
  # puts "XXXXXXXXX"
  # puts x
  flash[:info] = "Grreat."
  redirect '/feeds'
end

get '/stats' do
  # puts 'ALL users'
  # puts User.all.count
  if current_user.nil?
    redirect '/'
  end

  @item = Hash.new
  @items_posts = Hash.new
  User.all.each do |u|
    @items[u.name] = u.feeds.count
    @items_posts[u.name] = u.posts.count
  end
  return erb :stats, :layout => true
end

post '/create' do
  if current_user.nil?
    redirect '/'
  end

  @name = Sanitize.clean(params[:name]).strip
  @url = Sanitize.clean(params[:url]).strip

  begin
    HTTP.timeout(:global, :write => 1, :connect => 1, :read => 1).get(@url)
  rescue
    flash[:error] = "Is the site up? My code doesn't think so."
    redirect '/manage'
  end 

  if current_user.feeds.all.count < 100
    @feed = Feed.new
    @feed.name = @name
    @feed.url = @url
    # @feed.url_rss = Feedbag.find(@feed.url).last
    # puts Feedbag.find(@feed.url).red
    # if !@feed.url_rss.nil?
    if Feedbag.find(@feed.url).count > 0
      @feed.url_rss = Feedbag.find(@feed.url).last
      current_user.feeds.push(@feed)
      redirect '/manage'
    end
  end
  flash[:error] = 'no no no ... something went wrong! <br/> Wrong url ? Or fooling around ? I barely have validations on this shit. Be nice!'
  redirect '/manage'
end
