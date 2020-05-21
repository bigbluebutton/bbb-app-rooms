# frozen_string_literal: true

module TemporaryStore
  include ActiveSupport::Concern

  # creates temporary file with prefix, and return path name
  def store_temp_file(prefix, content)
    init_temp_file_storage
    clean_temp_files

    file = Tempfile.new(prefix, temp_file_folder)
    file.write(content)
    # close without unlinking
    file.close(false)
    file
  end

  def read_temp_file(file_path, delete = true)
    begin
      file = File.open(file_path, 'r')
    rescue
      return nil
    end
    contents = file.read
    file.close
    File.delete(file_path) if delete
    contents
  end

  private

  def temp_file_folder
    Rails.root.join('tmp', 'bbb-lti')
  end

  def temp_file_path(name)
    Rails.root.join('tmp', 'bbb-lti', name)
  end

  # delete temp files older than a day
  def clean_temp_files
    Dir.foreach(temp_file_folder).each do |filename|
      File.delete(temp_file_path(filename)) if File.file?(temp_file_path(filename)) && File.mtime(temp_file_path(filename)) < 12.hours.ago
    end
  end

  # create temp directory if it doesn't exist
  def init_temp_file_storage
    FileUtils.mkdir_p(temp_file_folder) unless Dir.exist? temp_file_folder
  end
end
