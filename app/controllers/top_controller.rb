require 'net/http'
require 'uri'
require 'set'
class TopController < ApplicationController
  skip_before_action :authenticate

  def index
  end

  def about
  end

  def confirm
    if params[:from_id]
      target_id = params[:twitter_id]

      if !valid_id_regexp.match?(target_id)
        redirect_to :root, alert: 'Twitterのスクリーンネーム(@から始まるID)を指定してください。' and return
      end

    elsif params[:from_url]
      target_url = params[:status_url]

      if !valid_status_url_regexp.match?(target_url)
        redirect_to :root, alert: 'ツイートのURLを正しく指定してください。' and return
      end
      match_result = valid_status_url_regexp.match(target_url)
      target_id = match_result[1]
      target_status = match_result[2].to_i
    else
      redirect_to :root, alert: '@から始まるIDかツイートのURLを指定してください。' and return
    end


    @include_following = params[:include_following]
    client = make_client(current_user)
    begin
      @target = client.user("@#{target_id}")
      @adq = advanced_query(params[:any_words], params[:none_words])
      search = client.search("to:#{target_id} #{@adq}", count: 100)
      @blocked_ids = Set.new(client.blocked_ids.to_a)
      @muted_ids = Set.new(client.muted_ids.to_a)

      @tweets = []
      search.each_slice(100){ |arr|
        a = arr.reject { |t|
          @blocked_ids.include?(t.user.id) \
          or @muted_ids.include?(t.user.id) \
          or t.user.id == @target.id \
          or (!@include_following and t.user.following?)
        }
        if params[:from_url]
          a.select! { |t|
            t.in_reply_to_status_id == target_status
          }
        end
        @tweets += a
        if(@tweets.count > 100)
          @tweets = @tweets[0...100]
          break
        end
      }

      if @tweets.count == 0
        redirect_to :root, alert: "@#{target_id}にリプライを送っている人が見つかりませんでした。" and return
      end
    rescue Twitter::Error::NotFound => e
      redirect_to :root, alert: "@#{target_id}が見つかりませんでした。(#{e.to_s})" and return
    rescue Twitter::Error::TooManyRequests => e
      redirect_to :root, alert: "API叩きすぎで怒られました。時間をあけて再度お試しください。(#{e.to_s})" and return
    end
    @tweets_dict = {}
    @users = @tweets.map { |t|
        @tweets_dict[t.user] = t
        t.user
      }.uniq
    if @users.count == 0
        redirect_to :root, alert: "ブロックできる人が見つかりませんでした。" and return
    end
    @since_id, @max_id = @tweets.minmax{ | a, b |
      a.id <=> b.id
    }.map { |t| t.id }
    @rate_limit = get_rate_limit_for_search(client)
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

  def get_rate_limit_for_search(client)
    (Twitter::REST::Request.new(client, :get, '/1.1/application/rate_limit_status.json').perform)[:resources][:search][:'/search/tweets']
  end

  def valid_id_regexp()
    Regexp.compile("[0-9a-zA-Z_]{1,15}")
  end

  def valid_status_url_regexp()
    Regexp.compile('^https?:\/\/twitter\.com\/(?:#!\/)?(.*)\/status(?:es)?\/(\d+)$')
  end

  def expand_url(url)
  begin
    response = Net::HTTP.get_response(URI.parse(url))
  rescue
    return url
  end
  case response
  when Net::HTTPRedirection
    expand_url(response['location'])
  else
    url
  end
end
end
