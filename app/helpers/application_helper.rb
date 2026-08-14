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

  def activity_summary_polyline(activity)
    activity.dig("map", "summary_polyline").to_s.presence
  end

  def format_pace(meters_per_second)
    return "—" if meters_per_second.to_f.zero?

    seconds_per_km = 1000.0 / meters_per_second.to_f
    minutes = (seconds_per_km / 60).floor
    seconds = (seconds_per_km % 60).round

    if seconds == 60
      minutes += 1
      seconds = 0
    end

    format("%d:%02d /km", minutes, seconds)
  end

  def render_overlay_export_button(activity: @activity)
    render("activities/overlay_export", activity: activity)
  end

  def format_duration_hms(seconds)
    total = seconds.to_i
    return "0:00:00" if total.zero?

    hours = total / 3600
    minutes = (total % 3600) / 60
    secs = total % 60
    format("%d:%02d:%02d", hours, minutes, secs)
  end

  def format_rest_time(seconds)
    total = seconds.to_i
    return "0m" if total.zero?

    minutes = total / 60
    secs = total % 60
    format("%d:%02d", minutes, secs)
  end

  def format_efficiency_ratio(moving_time, elapsed_time)
    moving = moving_time.to_f
    elapsed = elapsed_time.to_f
    return "—" if elapsed.zero?

    ratio = (moving / elapsed) * 100
    format("%.0f%% Active", ratio)
  end

  def format_pace_or_speed(activity)
    speed = activity["average_speed"].to_f
    return "—" if speed.zero?

    type = activity["type"].to_s.downcase
    if %w[run walk hike].include?(type)
      format_pace(speed)
    else
      format_speed(speed)
    end
  end

  def format_pace_or_speed_label(activity)
    type = activity["type"].to_s.downcase
    %w[run walk hike].include?(type) ? "Avg Pace" : "Avg Speed"
  end

  def format_elevation_range(low, high)
    return "—" if low.to_f.zero? && high.to_f.zero?

    "#{low.to_f.round}–#{high.to_f.round} m"
  end

  def format_watts(watts)
    return "—" if watts.to_f.zero?

    "#{watts.to_i} W"
  end

  def format_kilojoules(kj)
    return "—" if kj.to_f.zero?

    "#{kj.to_i} kJ"
  end

  def format_cadence(cadence)
    return "—" if cadence.to_f.zero?

    "#{cadence.to_i} rpm"
  end

  def format_temperature(celsius)
    return "—" if celsius.blank?

    "#{celsius.to_f.round}°C"
  end

  def format_gear_id(gear_id)
    gear_id.to_s.presence || "—"
  end

  def format_device_name(device_name)
    device_name.to_s.presence || "—"
  end

  def format_suffer_score(score)
    return "—" if score.to_i.zero?

    score.to_i
  end

  def format_pr_count(count)
    return "—" if count.to_i.zero?

    pluralize(count.to_i, "PR")
  end

  def format_achievement_count(count)
    return "—" if count.to_i.zero?

    pluralize(count.to_i, "Achievement")
  end

  def activity_photo_urls(photos)
    return [] if photos.blank?

    urls = []

    if photos.is_a?(Hash)
      primary = photos["primary"]
      if primary.is_a?(Hash) && primary["urls"].is_a?(Hash)
        urls.concat(primary["urls"].values.reverse)
      end

      if photos["data"].is_a?(Array)
        photos["data"].each do |photo|
          if photo.is_a?(Hash) && photo["urls"].is_a?(Hash)
            urls.concat(photo["urls"].values)
          end
        end
      end
    end

    urls.compact.uniq
  end

  def metric_card(label:, value:, icon:, icon_class:)
    content_tag(:div, class: "rounded-xl border bg-card p-4 text-card-foreground shadow") do
      safe_join([
        content_tag(:div, class: "flex items-center justify-between") do
          safe_join([
            content_tag(:span, label, class: "text-xs font-medium uppercase tracking-wide text-muted-foreground"),
            icon_badge(icon, icon_class)
          ])
        end,
        content_tag(:div, value.to_s, class: "mt-2 text-2xl font-bold tracking-tight sm:text-3xl")
      ])
    end
  end

  def small_metric(label:, value:)
    content_tag(:div, class: "rounded-lg border bg-muted/30 p-3") do
      safe_join([
        content_tag(:div, label, class: "text-xs font-medium uppercase tracking-wide text-muted-foreground"),
        content_tag(:div, value.to_s, class: "mt-1 text-lg font-bold")
      ])
    end
  end

  def metadata_row(icon:, label:, value:)
    content_tag(:div, class: "flex items-center justify-between border-b border-border pb-3 last:border-0 last:pb-0") do
      safe_join([
        content_tag(:div, class: "flex items-center gap-2 text-sm text-muted-foreground") do
          safe_join([
            inline_icon(icon, classes: "h-4 w-4"),
            label
          ])
        end,
        content_tag(:span, value.to_s, class: "text-sm font-medium")
      ])
    end
  end

  def icon_badge(icon, icon_class)
    content_tag(:div, class: "rounded-full p-2 #{icon_class}") do
      inline_icon(icon, classes: "h-4 w-4")
    end
  end

  def inline_icon(name, classes: nil)
    svg = case name.to_s
    when "map-pin"
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/></svg>'
    when "timer"
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="10" x2="14" y1="2" y2="2"/><line x1="12" x2="15" y1="14" y2="11"/><circle cx="12" cy="14" r="8"/></svg>'
    when "clock"
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>'
    when "gauge"
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 14 4-4"/><path d="M3.34 19a10 10 0 1 1 17.32 0"/></svg>'
    when "flame"
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/></svg>'
    when "mountain"
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m8 3 4 8 5-5 5 15H2L8 3z"/></svg>'
    when "bike"
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="18.5" cy="17.5" r="3.5"/><circle cx="5.5" cy="17.5" r="3.5"/><circle cx="15" cy="5" r="1"/><path d="M12 17.5V14l-3-3 4-3 2 3h2"/></svg>'
    when "smartphone"
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><path d="M12 18h.01"/></svg>'
    when "trophy"
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2z"/></svg>'
    when "medal"
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7.21 15 2.66 7.14a2 2 0 0 1 .13-2.2L4.4 2.8A2 2 0 0 1 6 2h12a2 2 0 0 1 1.6.8l1.6 2.14a2 2 0 0 1 .14 2.2L16.79 15"/><path d="M11 12 5.12 2.2"/><path d="m13 12 5.88-9.8"/><path d="M8 7h8"/><circle cx="12" cy="17" r="5"/><path d="m9 17-2-2"/><path d="m15 17 2-2"/></svg>'
    when "thermometer"
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 4v10.54a4 4 0 1 1-4 0V4a2 2 0 0 1 4 0Z"/></svg>'
    else
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/></svg>'
    end

    raw(svg.sub(/class="h-4 w-4"/, "class=\"#{classes}\""))
  end
end
