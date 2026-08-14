class User < ApplicationRecord
  has_many :weekly_summaries, dependent: :destroy

  validates :strava_id, presence: true, uniqueness: true
  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :token_expires_at, presence: true

  def token_expired?
    token_expires_at.nil? || token_expires_at <= Time.now.to_i
  end
end
