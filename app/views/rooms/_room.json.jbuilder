json.extract! room, :id, :name, :description, :welcome, :moderator, :viewer, :recording, :wait_moderator, :all_moderators, :created_at, :updated_at
json.url room_url(room, format: :json)
