module ElosHelper

  def format_date(date, format=:short_custom, include_time=true)
    if date.present?
      if date.is_a?(Integer) && date.to_s.length == 13
        value = Time.zone.at(date/1000)
      else
        value = Time.zone.at(date)
      end
      if include_time
        I18n.l(value, format: format)
      else
        I18n.l(value.to_date, format: format)
      end
    else
      nil
    end
  end

  def recording_duration_secs(recording)
    playbacks = recording[:playbacks]
    valid_playbacks = playbacks.reject { |p| p[:type] == 'statistics' }
    return 0 if valid_playbacks.empty?

    len = valid_playbacks.first[:length]
    return 0 if len.nil?

    len * 60
  end

  def duration_in_hours_and_minutes(duration)
    distance_of_time_in_hours_and_minutes(0, duration)
  end

  def distance_of_time_in_hours_and_minutes(from_time, to_time)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_hours   = (((to_time - from_time).abs) / 3600).floor
    distance_in_minutes = ((((to_time - from_time).abs) % 3600) / 60).round

    words = ''

    if distance_in_hours > 0
      words << I18n.t('helpers.distance_of_time_in_hours_and_minutes.hour', count: distance_in_hours)
      if distance_in_minutes > 0
        words << " #{I18n.t('helpers.distance_of_time_in_hours_and_minutes.connector')} "
      end
    end

    if distance_in_minutes > 0
      words << I18n.t('helpers.distance_of_time_in_hours_and_minutes.minute', count: distance_in_minutes)
    end

    words
  end

  def current_formatted_time_zone
    ActiveSupport::TimeZone[Time.zone.name].to_s.gsub(/[^\s]*\//, '').gsub(/_/, ' ')
  end
end
