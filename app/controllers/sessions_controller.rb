class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    redirect_to root_path if current_user
  end

  def create
    redirect_to StravaService.authorization_url, allow_other_host: true
  end

  def strava_callback
    tokens = StravaService.exchange_code(params[:code])
    user = upsert_user(tokens)
    session[:user_id] = user.id

    redirect_to root_path, notice: "Welcome back, #{user.name}!"
  rescue Faraday::Error, KeyError, ActiveRecord::RecordInvalid => e
    Rails.logger.error("Strava OAuth failed: #{e.message}")
    redirect_to login_path, alert: "Strava authentication failed. Please try again."
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "You have been signed out."
  end

  private

  def upsert_user(tokens)
    athlete = tokens.fetch(:athlete, {})
    user = User.find_or_initialize_by(strava_id: athlete["id"].to_s)
    user.update!(
      access_token: tokens[:access_token],
      refresh_token: tokens[:refresh_token],
      token_expires_at: tokens[:expires_at],
      name: [ athlete["firstname"], athlete["lastname"] ].compact.join(" ").presence || "Athlete",
      avatar_url: athlete["profile"]
    )
    user
  end
end
