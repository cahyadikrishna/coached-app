module ApplicationHelper
  def format_distance(meters)
    return "0 km" if meters.to_f.zero?

    format("%.1f km", meters.to_f / 1000)
  end

  def format_duration(seconds)
    hours = seconds.to_i / 3600
    minutes = (seconds.to_i % 3600) / 60
    rem = seconds.to_i % 60

    if hours.positive?
      format("%dh %02dm", hours, minutes)
    elsif minutes.positive?
      format("%dm %02ds", minutes, rem)
    else
      "#{rem}s"
    end
  end

  def format_elevation(meters)
    "#{meters.to_f.round} m"
  end

  def format_speed(meters_per_second)
    return "—" if meters_per_second.to_f.zero?

    format("%.1f km/h", meters_per_second.to_f * 3.6)
  end

  def format_date(value)
    value.present? ? Date.parse(value.to_s).strftime("%b %d, %Y") : "—"
  end

  def activity_type_badge(type)
    label = type.to_s.titleize
    ui_badge(label, variant: :secondary)
  end
end
