class ScheduledMeeting < ApplicationRecord
  belongs_to :room

  validates :room, presence: true
  validates :name, presence: true
  validates :start_at, presence: true
  validates :duration, presence: true

  after_initialize :init

  def self.from_param(param)
    find_by(id: param)
  end

  def self.durations_for_select(locale)
    {
      '5m': 5 * 60,
      '10m': 10 * 60,
      '15m': 15 * 60,
      '20m': 20 * 60,
      '30m': 30 * 60,
      '45m': 45 * 60,
      '1h': 60 * 60,
      '2h': 2 * 60 * 60,
      '3h': 3 * 60 * 60,
      '4h': 4 * 60 * 60,
      'more': 24 * 60 * 60,
    }.map { |k, v|
      [I18n.t("default.scheduled_meeting.durations.#{k}", locale: locale), v]
    }
  end

  def to_param
    self.id.to_s
  end

  def self.parse_start_at(date, time, locale = I18n.locale, zone = Time.zone)
    format_date = I18n.t('default.formats.flatpickr.date_ruby', locale: locale)
    format_time = I18n.t('default.formats.flatpickr.time_ruby', locale: locale)

    zone = ActiveSupport::TimeZone[zone] if zone.is_a?(String)
    zone_str = Time.at(zone.utc_offset.abs).utc.strftime(format_time)
    zone_sig = zone.utc_offset < 0 ? '-' : '+'

    # format string example: "%Y-%m-%dT%H:%M%z"
    DateTime.strptime(
      "#{date}T#{time}#{zone_sig}#{zone_str}", "#{format_date}T#{format_time}%z"
    )
  end

  def meeting_id
    "#{room.handler}-#{self.created_at.to_i}"
  end

  def start_at_date(locale)
    format = I18n.t('default.formats.flatpickr.date_ruby', locale: locale)
    self.start_at.strftime(format) if self.start_at
  end

  def start_at_time(locale)
    format = I18n.t('default.formats.flatpickr.time_ruby', locale: locale)
    self.start_at.strftime(format) if self.start_at
  end

  def broadcast_conference_started
    ActionCable.server.broadcast(
      "wait_channel:room_#{self.room.id}:meeting_#{self.id}",
      action: 'started'
    )
  end

  # Example of params:
  #   "date"=>"2020-06-12", "time"=>"17:15"
  def set_dates_from_params(params, locale = I18n.locale, zone = Time.zone)
    self.start_at = ScheduledMeeting.parse_start_at(params[:date], params[:time], locale, zone)
  end

  private

  def init
    self.duration ||= 60 * 60 # 1h
    self.start_at ||= (DateTime.now.utc + 1.hour).beginning_of_hour
  end
end
