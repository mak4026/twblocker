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
    client = make_client(current_user)
    begin
      @target = client.user("@#{target_id}")
    rescue Twitter::Error::NotFound => e
      redirect_to :root, alert: "@#{target_id}が見つかりませんでした" and return
    end
    @tweets = client.search("to:#{target_id}", count: 10)
    if @tweets.count == 0
      redirect_to :root, alert: "@#{target_id}にリプライを送っている人が見つかりませんでした" and return
    end
    @users = @tweets.map { |t| t.user }.uniq
    @since_id, @max_id = @tweets.minmax{ | a, b |
      a.id <=> b.id
    }.map { |t| t.id }
  end

  def block
    data = JSON.parse(params['target']['data'])
    target_name = data['target_name']
    max_id = data['max_id']
    since_id = data['since_id']
    client = make_client(current_user)
    tweets = client.search("to:#{target_name}", count: 10, max_id: max_id+1, since_id: since_id-1)
    users = tweets.map { |t| t.user }.uniq
    blocked_users = client.block(users)
    redirect_to :root, flash: {success: "#{blocked_users.count} 人のブロックに成功しました" }
  end

  private

  def make_client(user)
    twitter_auth = user.authentications.first
    client = Twitter::REST::Client.new do |config|
        config.consumer_key        = Settings.twitter_key
        config.consumer_secret     = Settings.twitter_secret
        config.access_token        = twitter_auth.token
        config.access_token_secret = twitter_auth.secret
    end
    return client
  end
end
