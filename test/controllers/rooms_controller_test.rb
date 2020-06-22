# frozen_string_literal: true

require 'test_helper'

class RoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @room = rooms(:one)
    launch_params = { 'custom_params' => {},
                      'ext_params' => { 'ext_user_username' => 'user', 'ext_lms' => 'moodle-2' },
                      'unknown_params' => { 'state' => 'state737b0d4447d9e575042f08dd8b390a34',
                                            'controller' => 'message',
                                            'action' => 'openid_launch_request',
                                            'app' => 'rooms',
                                            'lis_person_lis_person_name_family' => 'User', },
                      'resource_link_id' => '1',
                      'context_id' => '2',
                      'launch_presentation_return_url' => 'http://moodle.amy.blindside-dev.com/mod/lti/return.php?course=2&launch_container=4&instanceid=1&sesskey=tWdVjYYnpC',
                      'tool_consumer_instance_guid' => 'moodle.amy.blindside-dev.com',
                      'user_id' => '2',
                      'lis_person_sourcedid' => '',
                      'lis_result_sourcedid' => '{"data":{"instanceid":"1","userid":"2","typeid":"1","launchid":534250076},"hash":"6dfcfee4f4331a9271e9bcac939267b5b89440ce546be885abd2b8dd12f7006b"}',
                      'lis_outcome_service_url' => 'http://moodle.amy.blindside-dev.com/mod/lti/service.php',
                      'context_label' => 'course',
                      'context_title' => 'Course',
                      'lis_person_name_full' => 'Admin User',
                      'lis_person_name_given' => 'Admin',
                      'lis_person_contact_email_primary' => 'user@example.com',
                      'tool_consumer_info_product_family_code' => 'moodle',
                      'tool_consumer_info_version' => '2019052003',
                      'tool_consumer_instance_name' => 'uni',
                      'tool_consumer_instance_description' => 'University',
                      'resource_link_title' => 'lesson 1',
                      'resource_link_description' => '',
                      'launch_presentation_locale' => 'en',
                      'launch_presentation_document_target' => 'window',
                      'lti_version' => '1.3.0',
                      'roles' => 'Administrator,Instructor,Administrator',
                      'lti_message_type' => 'basic-lti-launch-request', }
    cookies['handler'] = launch_params.to_json
  end

  test 'should get index' do
    get rooms_url
    assert_response :success
  end

  test 'should get new' do
    get new_room_url
    assert_response :success
  end

  test 'should create room' do
    assert_difference('Room.count') do
      post rooms_url, params: { room:
      { all_moderators: @room.all_moderators,
        description: @room.description,
        moderator: @room.moderator,
        name: @room.name,
        recording: @room.recording,
        viewer: @room.viewer,
        wait_moderator: @room.wait_moderator,
        welcome: @room.welcome, } }
    end

    assert_redirected_to room_url(Room.last)
  end

  test 'should show room' do
    get room_url(@room)
    assert_response :success
  end

  test 'should get edit' do
    get edit_room_url(@room)
    assert_response :success
  end

  test 'should update room' do
    patch room_url(@room), params:
    { room:
    { all_moderators: @room.all_moderators,
      description: @room.description,
      moderator: @room.moderator,
      name: @room.name,
      recording: @room.recording,
      viewer: @room.viewer,
      wait_moderator: @room.wait_moderator,
      welcome: @room.welcome, } }
    assert_redirected_to room_url(@room)
  end

  test 'should destroy room' do
    assert_difference('Room.count', -1) do
      delete room_url(@room)
    end

    assert_redirected_to rooms_url
  end
end
