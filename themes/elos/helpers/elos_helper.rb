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
    len = valid_playbacks.first[:length]
    if len.nil?
      0
    else
      len * 60
    end
  end
end
