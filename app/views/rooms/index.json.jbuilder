# frozen_string_literal: true

json.array!(@rooms, partial: 'rooms/room', as: :room)
