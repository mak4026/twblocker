class TopController < ApplicationController
  skip_before_action :authenticate

  def index
  end

  def confirm
    @target_id = params[:twitter_id]
    valid_id_regexp = Regexp.compile("[0-9a-zA-Z_]{1,15}")
    if !valid_id_regexp.match?(@target_id)
      redirect_to :root, alert: 'Twitterのスクリーンネーム(@から始まるID)を指定してください'
    end
  end
end
