class ActivitiesController < ApplicationController
  def index
    @activities = StravaService.new(current_user).recent_activities(days: 7)
    @stats = aggregate_stats(@activities)
  rescue Faraday::Error => e
    Rails.logger.error("Strava activities fetch failed: #{e.message}")
    flash.now[:alert] = "Unable to load your Strava activities. Please try again later."
    @activities = []
    @stats = aggregate_stats([])
  end

  def show
    @activity = StravaService.new(current_user).activity(params[:id])
  rescue Faraday::Error => e
    Rails.logger.error("Strava activity fetch failed: #{e.message}")
    redirect_to activities_path, alert: "That activity could not be found."
  end

  private

  def aggregate_stats(activities)
    {
      total_activities: activities.size,
      total_distance: activities.sum { |a| a["distance"].to_f },
      total_moving_time: activities.sum { |a| a["moving_time"].to_i },
      total_elevation: activities.sum { |a| a["total_elevation_gain"].to_f }
    }
  end
end
