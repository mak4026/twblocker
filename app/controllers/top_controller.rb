class TopController < ApplicationController
  skip_before_action :authenticate

  def index
  end

  def about
  end

  def confirm
    target_id = params[:twitter_id]
    valid_id_regexp = Regexp.compile("[0-9a-zA-Z_]{1,15}")
    if !valid_id_regexp.match?(target_id)
      redirect_to :root, alert: 'Twitterのスクリーンネーム(@から始まるID)を指定してください。' and return
    end
    @include_following = params[:include_following]
    client = make_client(current_user)
    begin
      @target = client.user("@#{target_id}")
      @adq = advanced_query(params[:any_words], params[:none_words])
      @tweets = client.search("to:#{target_id} #{@adq}", count: 10).take(100)
      if @tweets.count == 0
        redirect_to :root, alert: "@#{target_id}にリプライを送っている人が見つかりませんでした。" and return
      end
      @blocked_ids = client.blocked_ids.attrs[:ids]
    rescue Twitter::Error::NotFound => e
      redirect_to :root, alert: "@#{target_id}が見つかりませんでした。(#{e.to_s})" and return
    rescue Twitter::Error::TooManyRequests => e
      redirect_to :root, alert: "API叩きすぎで怒られました。時間をあけて再度お試しください。(#{e.to_s})" and return
    end
    @tweets_dict = {}
    @users = @tweets.map { |t|
        @tweets_dict[t.user] = t
        t.user
      }.uniq.reject{ |u|
      @blocked_ids.include?(u.id) or u.id == @target.id or (!@include_following and u.following?)
    }
    if @users.count == 0
        redirect_to :root, alert: "ブロックできる人が見つかりませんでした。" and return
    end
    @since_id, @max_id = @tweets.minmax{ | a, b |
      a.id <=> b.id
    }.map { |t| t.id }
  end

  def block
    users = JSON.parse(params['target']['data'])
    client = make_client(current_user)
    if params['mute']
      blocked_users = client.mute(users)
      act_msg = "ミュート"
    else
      blocked_users = client.block(users)
      act_msg = "ブロック"
    end
    block_count = blocked_users.count
    redirect_to :root, flash: {success: "#{block_count} 人の#{act_msg}に成功しました\n#{block_count_message(block_count)}" }
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

  def block_count_message(count)
    case count
    when 1..9
      "少しスッキリしましたね！"
    when 10..50
      "快適なTwitterライフに近づきました！"
    else
      "たのしー！"
    end
  end

  def advanced_query(any_words, none_words)
    any_q = words_split(any_words).join(' OR ')
    none_q = words_split(none_words).map{ |s|
        '-'+s
      }.join(' ')
    any_q + " " + none_q
  end

  def words_split(string)
    string.gsub(/(^(\s|　)+)|((\s|　)+$)/, '').split(/[[:blank:]]+/)
  end
end
