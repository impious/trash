class Feed
  include Mongoid::Document
  include Mongoid::Timestamps

  field :url, type: String
  field :url_rss, type: String
  field :name, type: String

  validates_presence_of :name, :url

  belongs_to :user

  # fulltext_search_in :url, :name
  # def self
  #   Feed.update_ngram_index
  # end

end

class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  # include Mongoid::FullTextSearch
  include Mongoid::Search

  field :url, type: String
  field :name, type: String
  field :feed_name, type: String

  belongs_to :user

  validates_uniqueness_of :url, :name

  search_in :url, :name, :feed_name


  # fulltext_search_in :url, :name
  # def self
  #   Post.update_ngram_index
  # end

end


class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :provider, type: String
  field :uid, type: String
  field :name, type: String
  field :avatar, type: String
  field :oauth_token, type: String
  field :oauth_expires_at, type: Time

  has_many :feeds
  has_many :posts

  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_initialize.tap do |user|
      logger.info("mother fado")
      logger.info("mother fado")
      logger.info("mother fado")
      user.provider = auth.provider
      user.uid = auth.uid
      user.name = auth.info.name
      user.avatar = auth.info.image
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.save!
    end
  end

  def self.get_user(val)
    User.find_by(uid: val)
  end

end