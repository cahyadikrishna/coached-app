class StravaService
  AUTH_URL = "https://www.strava.com/oauth/authorize"
  TOKEN_URL = "https://www.strava.com/oauth/token"
  API_URL = "https://www.strava.com/api/v3"

  SCOPE = "read,activity:read_all"

  class Error < StandardError; end

  attr_reader :user

  def self.authorization_url
    params = {
      client_id: ENV.fetch("STRAVA_CLIENT_ID"),
      redirect_uri: ENV.fetch("STRAVA_REDIRECT_URI"),
      response_type: "code",
      approval_prompt: "force",
      scope: SCOPE
    }
    "#{AUTH_URL}?#{params.to_query}"
  end

  def self.exchange_code(code)
    response = token_connection.post(TOKEN_URL) do |req|
      req.body = {
        client_id: ENV.fetch("STRAVA_CLIENT_ID"),
        client_secret: ENV.fetch("STRAVA_CLIENT_SECRET"),
        code: code,
        grant_type: "authorization_code"
      }
    end

    {
      access_token: response.body["access_token"],
      refresh_token: response.body["refresh_token"],
      expires_at: response.body["expires_at"],
      athlete: response.body["athlete"]
    }
  end

  def initialize(user)
    @user = user
  end

  def access_token
    refresh_token! if user.token_expired?
    user.access_token
  end

  def recent_activities(days: 7)
    response = api_connection.get("athlete/activities", after: (Time.now - days.days).to_i, per_page: 100)
    response.body
  end

  def activity(id)
    response = api_connection.get("activities/#{id}")
    response.body
  end

  private

  def self.token_connection
    Faraday.new(url: TOKEN_URL) do |conn|
      conn.request :url_encoded
      conn.response :raise_error
      conn.response :json
    end
  end

  def refresh_token!
    response = self.class.token_connection.post(TOKEN_URL) do |req|
      req.body = {
        client_id: ENV.fetch("STRAVA_CLIENT_ID"),
        client_secret: ENV.fetch("STRAVA_CLIENT_SECRET"),
        refresh_token: user.refresh_token,
        grant_type: "refresh_token"
      }
    end

    body = response.body
    user.update!(
      access_token: body["access_token"],
      refresh_token: body["refresh_token"] || user.refresh_token,
      token_expires_at: body["expires_at"]
    )
  end

  def api_connection
    Faraday.new(url: API_URL) do |conn|
      conn.response :raise_error
      conn.response :json
      conn.headers["Authorization"] = "Bearer #{access_token}"
    end
  end
end
