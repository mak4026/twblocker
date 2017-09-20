class TopController < ApplicationController
  skip_before_action :authenticate

  def index
  end

  def confirm
    @target_id = params[:twitter_id]
  end
end
