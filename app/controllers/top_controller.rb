class TopController < ApplicationController
  skip_before_action :authenticate

  def index
  end

  def confirm
    target_id = params[:twitter_id]
    valid_id_regexp = Regexp.compile("[0-9a-zA-Z_]{1,15}")
    if !valid_id_regexp.match?(target_id)
      redirect_to :root, alert: 'Twitterのスクリーンネーム(@から始まるID)を指定してください' and return
    end
    twitter_auth = current_user.authentications.find_by(provider: "twitter")
    client = Twitter::REST::Client.new do |config|
        config.consumer_key        = Settings.twitter_key
        config.consumer_secret     = Settings.twitter_secret
        config.access_token        = twitter_auth.token
        config.access_token_secret = twitter_auth.secret
    end
    begin
      @target = client.user("@#{target_id}")
      @tweets = client.search("to:@#{target_id}", count: 10)
    rescue Twitter::Error::NotFound => e
      redirect_to :root, alert: "@#{@target_id}が見つかりませんでした" and return
    end
  end
end
