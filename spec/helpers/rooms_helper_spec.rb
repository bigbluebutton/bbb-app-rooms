# frozen_string_literal: true

RSpec.describe(RoomsHelper, type: :helper) do
  describe '#elapsed_time' do
    it 'returns the elapsed time' do
      time = DateTime.new(2001, 2, 3, 4, 5, 6)
      expect(helper.elapsed_time(time, time)).to(eql('00:00:00'))
    end
  end
end
