# frozen_string_literal: true

require 'rails_helper'

describe RoomsController, type: :controller do
  let(:rooms) { Room.all }

  before :each do
    allow_any_instance_of(RoomsController).to(receive(:authenticate_user!).and_return(:success))

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

    # Currently a new room is created before every test. This could be optimized by creating a new room only before tests that require it.
    @room = create(:room)
  end

  describe '#create' do
    it 'creates a new room with room information' do
      expect do
        post :create, params: {
          room: {
            name: 'rspec room',
            description: 'description',
            handler: :launch_params,
            recording: false,
            wait_moderator: false,
            all_moderators: false,
          },
        }
      end.to(change { Room.count }.by(1))
    end
  end

  describe '#show' do
    it 'should show the page for the room' do
      expect(get(:show, params: { id: @room.id })).to(have_http_status(:ok))
    end
  end

  describe '#destroy' do
    it 'should delete the room' do
      expect { delete :destroy, params: { id: @room.id } }.to(change { Room.count }.by(-1))
    end
  end

  describe '#edit' do
    it 'gets the edit room' do
      get :edit, params: { id: @room.id }
      expect(response). to(have_http_status(:success))
    end
  end

  describe '#new' do
    it 'creates a new room' do
      get :new
      expect(response). to(have_http_status(:success))
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
      expect(response). to(have_http_status(:success))
    end
  end
end
