class AiCoachService
  class Error < StandardError; end
  class NoActivitiesError < Error; end

  SYSTEM_PROMPT = <<~PROMPT
    You are a friendly, knowledgeable endurance-sports coach. You analyze an
    athlete's recent training data and write a concise, encouraging weekly
    coaching summary. Use plain language, highlight trends, and suggest one or
    two concrete, actionable recommendations for the coming week. Keep the
    summary under 250 words and format it with short paragraphs and a bullet
    list where helpful.
  PROMPT

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def generate_weekly_summary!
    activities = strava_service.recent_activities(days: 7)
    raise NoActivitiesError, "No Strava activities found in the last 7 days" if activities.empty?

    metrics = aggregate_metrics(activities)
    content = request_summary(activities, metrics)

    user.weekly_summaries.create!(
      start_date: Date.current - 6.days,
      end_date: Date.current,
      metrics: metrics,
      content: content
    )
  end

  private

  def strava_service
    @strava_service ||= StravaService.new(user)
  end

  def client
    @client ||= OpenAI::Client.new(
      uri_base: ENV.fetch("DEEPSEEK_API_BASE", "https://api.deepseek.com"),
      access_token: ENV.fetch("DEEPSEEK_API_KEY")
    )
  end

  def aggregate_metrics(activities)
    total_distance = activities.sum { |a| a["distance"].to_f }
    total_moving_time = activities.sum { |a| a["moving_time"].to_i }
    total_elevation = activities.sum { |a| a["total_elevation_gain"].to_f }

    type_counts = activities.each_with_object(Hash.new(0)) { |a, h| h[a["type"]] += 1 }

    longest = activities.max_by { |a| a["distance"].to_f }
    highest = activities.max_by { |a| a["total_elevation_gain"].to_f }

    {
      "total_activities" => activities.size,
      "total_distance_meters" => total_distance.round,
      "total_moving_time_seconds" => total_moving_time,
      "total_elevation_gain_meters" => total_elevation.round,
      "activity_types" => type_counts,
      "longest_activity" => activity_breakdown(longest),
      "most_elevation_activity" => activity_breakdown(highest)
    }
  end

  def activity_breakdown(activity)
    return {} if activity.nil?

    {
      "name" => activity["name"],
      "type" => activity["type"],
      "distance_meters" => activity["distance"].to_f.round,
      "moving_time_seconds" => activity["moving_time"].to_i,
      "elevation_gain_meters" => activity["total_elevation_gain"].to_f.round
    }
  end

  def request_summary(activities, metrics)
    response = client.chat(
      parameters: {
        model: ENV.fetch("DEEPSEEK_MODEL", "deepseek-chat"),
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: build_prompt(activities, metrics) }
        ],
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content").presence ||
      raise(Error, "DeepSeek returned an empty response")
  end

  def build_prompt(activities, metrics)
    <<~PROMPT
      Here is my training data for the last 7 days (#{Date.current - 6.days} to #{Date.current}):

      Aggregated metrics:
      - Total activities: #{metrics["total_activities"]}
      - Total distance: #{format_distance(metrics["total_distance_meters"])}
      - Total moving time: #{format_duration(metrics["total_moving_time_seconds"])}
      - Total elevation gain: #{format_elevation(metrics["total_elevation_gain_meters"])}
      - Activity types: #{metrics["activity_types"].map { |type, count| "#{type} (#{count})" }.join(", ")}

      Individual activities:
      #{activities.map { |a| activity_line(a) }.join("\n")}

      Please write my weekly coaching summary.
    PROMPT
  end

  def activity_line(activity)
    [
      activity["start_date_local"],
      activity["type"],
      activity["name"],
      format_distance(activity["distance"]),
      format_duration(activity["moving_time"])
    ].compact.join(" | ")
  end

  def format_distance(meters)
    return "0 km" if meters.to_f.zero?

    format("%.1f km", meters.to_f / 1000)
  end

  def format_duration(seconds)
    hours = seconds.to_i / 3600
    minutes = (seconds.to_i % 3600) / 60
    hours.positive? ? "#{hours}h #{minutes}m" : "#{minutes}m"
  end

  def format_elevation(meters)
    format("%.0f m", meters.to_f)
  end
end
