# frozen_string_literal: true

require 'rails_helper'

describe RoomsController, type: :controller do
  let(:rooms) { Room.all }
  let(:bbb_api) { BigBlueButton::BigBlueButtonApi.new('http://bbb.example.com/bigbluebutton/api', 'secret', '1.0', Rails.logger) }

  before :each do
    allow_any_instance_of(RoomsController).to(receive(:authenticate_user!).and_return(:success))
    allow_any_instance_of(RoomsController).to(receive(:bbb).and_return(bbb_api))
    allow_any_instance_of(NotifyMeetingWatcherJob).to(receive(:bbb).and_return(bbb_api)) # stub actioncable processes
    allow_any_instance_of(BrokerHelper).to(receive(:tenant_settings).and_return({
                                                                                  'handler_params' => 'context_id',
                                                                                  'hide_build_tag' => 'false',
                                                                                  'bigbluebutton_url' => 'https://example-bbb-server.com/bigbluebutton/api',
                                                                                  'bigbluebutton_secret' => 'supersecretsecret',
                                                                                  'enable_shared_rooms' => 'true',
                                                                                  'bigbluebutton_moderator_roles' => 'administrator,teacher',
                                                                                }))

    @request.session['handler'] = {
      user_params: {
        uid: 'uid',
        full_name: 'Jane Doe',
        first_name: 'Jane',
        last_name: 'Doe',
        email: 'jane.doe@email.com',
        roles: 'Administrator,Instructor,Administrator',

      },
    }

    @user = BbbAppRooms::User.new(uid: 'uid',
                                  full_name: 'Jane Doe',
                                  first_name: 'Jane',
                                  last_name: 'Doe',
                                  email: 'jane.doe@email.com',
                                  roles: 'Administrator,Instructor,Administrator')

    # Currently a new room is created before every test. This could be optimized by creating a new room only before tests that require it.
    @room = create(:room)
  end

  describe '#create' do
    it 'creates a new room with room information' do
      expect do
        post(:create, params: {
               room: {
                 name: 'rspec room',
                 description: 'description',
                 handler: :launch_params,
                 recording: false,
                 wait_moderator: false,
                 all_moderators: false,
               },
             })
      end.to(change { Room.count }.by(1))
    end
  end

  describe '#show' do
    it 'should show the page for the room with no recordings' do
      expect(get(:show, params: { id: @room.id })).to(have_http_status(:ok))
    end

    it 'should show the page for the room with recordings' do
      @recordings = [
        {
          meetingID: @room.handler,
          name: Faker::Name.name,
          description: 'Sample description',
          participants: '3',
          playback: {
            format:
            {
              type: 'presentation',
              url: Faker::Internet.url,
            },
          },
        },
        {
          meetingID: @room.handler,
          name: Faker::Name.name,
          description: 'Sample description',
          participants: '5',
          playback: {
            format:
            {
              type: 'other',
              url: Faker::Internet.url,
            },
          },
        },
      ]
      expect(get(:show, params: { id: @room.id })).to(have_http_status(:ok))
    end
  end

  describe '#destroy' do
    it 'should delete the room' do
      expect { delete(:destroy, params: { id: @room.id }) }.to(change { Room.count }.by(-1))
    end
  end

  describe '#edit' do
    it 'gets the edit room' do
      get :edit, params: { id: @room.id }
      expect(response).to(have_http_status(:success))
    end
  end

  describe '#new' do
    it 'creates a new room' do
      get :new
      expect(response).to(have_http_status(:success))
    end
  end

  describe '#update' do
    it 'should redirect to edit url' do
      patch :update, params: {
        id: @room.id,
        room: {
          all_moderators: @room.all_moderators,
          description: @room.description,
          moderator: @room.moderator,
          name: @room.name,
          recording: @room.recording,
          viewer: @room.viewer,
          wait_moderator: @room.wait_moderator,
          welcome: @room.welcome,
        },
      }
    end
  end

  describe '#meeting_end' do
    it 'should end the meeting' do
      post :meeting_end, params: { id: @room.id }
      expect(response).to(have_http_status(:found))
    end
  end

  describe 'recordings' do
    context 'POST #recording_update' do
      it 'updates the recordings details' do
        allow_any_instance_of(BbbHelper).to(receive(:update_recording).and_return(updated: true))
        @request.session[:user_id] = @user.uid

        post :recording_update, params: { id: @room.id, record_id: Faker::IDNumber.valid, setting: 'rename_recording', record_name: 'New name' }

        expect(response).to(have_http_status(204))
      end
    end

    context 'DELETE #recording_delete' do
      it 'deletes the recording' do
        allow_any_instance_of(BbbHelper).to(receive(:delete_recording).and_return(true))
        @request.session[:user_id] = @user.uid

        post :recording_delete, params: { id: @room.id, record_id: Faker::IDNumber.valid }

        expect(response).to(have_http_status(302))
      end
    end

    context 'POST publish' do
      it 'publishes the recording' do
        allow_any_instance_of(BbbHelper).to(receive(:publish_recording).and_return(true))

        post :recording_publish, params: { id: @room.id, record_id: Faker::IDNumber.valid }

        expect(response).to(have_http_status(302))
      end

      it 'unpublishes the recording' do
        allow_any_instance_of(BbbHelper).to(receive(:unpublish_recording).and_return(true))

        post :recording_unpublish, params: { id: @room.id, record_id: Faker::IDNumber.valid }

        expect(response).to(have_http_status(302))
      end
    end
  end

  describe 'meeting configurations' do
    context 'wait for moderators' do
      it 'redirects the user to the wait page' do
        allow_any_instance_of(BbbHelper).to(receive(:wait_for_mod?).and_return(true))
        allow_any_instance_of(BbbHelper).to(receive(:meeting_running?).and_return(false))

        post :meeting_join, params: { id: @room.id }

        expect(response).to(render_template(:meeting_join))
      end
    end

    context 'all moderators' do
      it 'allows any user to start the meeting' do
        allow_any_instance_of(BbbHelper).to(receive(:wait_for_mod?).and_return(false))
        allow_any_instance_of(BbbHelper).to(receive(:meeting_running?).and_return(false))
        allow_any_instance_of(BbbHelper).to(receive(:join_meeting_url).and_return('bbb.example.com'))

        post :meeting_join, params: { id: @room.id }

        expect(response).to(redirect_to('bbb.example.com'))
      end
    end
  end
end
