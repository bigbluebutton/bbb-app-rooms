# frozen_string_literal: true

module PlatformGradesService
  include ActiveSupport::Concern

  # check if platform offers assignment/grades services
  def platform_has_ags?(jwt_body)
    jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint'].present?
  end

  # grade formated as a string
  def platform_grade(member, given_score, max_score, activity_progress = 'Completed', grading_progress = 'FullyGraded')
    {
      scoreGiven: 0 + given_score,
      scoreMaximum: 0 + max_score,
      activityProgress: activity_progress,
      gradingProgress: grading_progress,
      timestamp: DateTime.now.iso8601,
      userId: member['user_id']
    }.to_json
  end

  # get score url to post grades to
  def platform_score_url(jwt)
    score_url = jwt['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']['lineitem']
    uri = URI.parse(score_url)
    uri.path + '/scores'
    uri.to_s
  end

  # send grade to platform for one user
  def send_grade_to_platform(registration, scopes, score_url, grade, token)
    make_service_request(
      registration,
      scopes,
      'POST',
      score_url,
      grade,
      'application/vnd.ims.lis.v1.score+json',
      'application/json',
      token
    )
  end

  def resource_lineitem(registration, jwt)
    unless jwt['scope'].include? 'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'
      puts 'Missing scope for grades services'
      return nil
    end
    response = make_service_request(
      registration,
      jwt['scope'],
      'GET',
      jwt['lineitems'],
      nil,
      nil,
      'application/vnd.ims.lis.v2.lineitemcontainer+json'
    )

    line_items = JSON.parse(response.body)

    line_items.each do |line_item|
      return line_item
    end
  end

  # get grades associated with current registration
  def grades(registration, jwt)
    line_item = resource_lineitem(registration, jwt)

    return {} unless line_item.present?

    response = make_service_request(
      registration,
      jwt['scope'],
      'GET',
      grade_results_url(line_item['id']),
      nil,
      nil,
      'application/vnd.ims.lis.v2.resultcontainer+json'
    )
    JSON.parse(response.body)
  end

  def grade_results_url(results_url)
    uri = URI.parse(results_url)
    uri.path + '/results'
    uri.to_s
  end
end
