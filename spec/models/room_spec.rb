# frozen_string_literal: true

require 'rails_helper'

describe Room, type: :model do
  describe 'shared code validation' do
    it 'rejects a room using its own code as its shared code' do
      room = create(:room)
      room.use_shared_code = true
      room.shared_code = room.code

      expect(room).not_to(be_valid)
      expect(room.errors[:shared_code]).to(include("A room can't use its own code as a shared code"))
    end

    it "accepts another room's code from the same tenant" do
      room = create(:room)
      owner = create(:room, handler: 'owner-handler', tenant: room.tenant)
      room.use_shared_code = true
      room.shared_code = owner.code

      expect(room).to(be_valid)
    end

    it 'rejects a code that does not belong to any room in the tenant' do
      room = create(:room)
      room.use_shared_code = true
      room.shared_code = 'nonexistent'

      expect(room).not_to(be_valid)
      expect(room.errors[:shared_code]).to(include('A room with this code could not be found'))
    end
  end
end
