#!/bin/env ruby
# encoding: utf-8

require 'taglib'
require 'find'
require 'progress_bar'

BULK_TXT_PATH = "/tmp/bulk.txt"

desc "creates a songs bulk file for import"
task "songs:createbulk" => :environment  do
  MP3_FILE_PATHS = "/tmp/mp3_file_paths.txt"


  #
  #sudo mkdir /mnt/h
  #sudo mkdir /mnt/g
  #sudo mount -t vboxsf h_drive /mnt/h
  #sudo mount -t vboxsf g_drive /mnt/g
  #
  if(!File.exists?(MP3_FILE_PATHS))
    mp3_file_paths = Dir.glob("/mnt/g/**/*.mp3")
    mp3_file_paths << Dir.glob("/mnt/h/**/*.mp3")

    File.open(MP3_FILE_PATHS, "w+") {|f|
      f.write mp3_file_paths.join("\n")
    }
    puts "#{MP3_FILE_PATHS} was writed."
  elsif
    File.open(MP3_FILE_PATHS, 'r') do |f| mp3_file_paths = f.read.split("\n") end
  end

  puts "#{mp3_file_paths.length} files found"
  bar = ProgressBar.new(mp3_file_paths.length)
  file_content = ""
  this_file = ""
  date_now = Time.now.to_s

  count = 0
  mp3_file_paths.each do |file_path|
    begin
      TagLib::FileRef.open(file_path) do |fileref|
        tag = fileref.tag
        properties = fileref.audio_properties

        this_file = file_path << "|"

        if !tag.nil?
          this_file << make_safe_field_string(tag.artist) << "|"
          this_file << make_safe_field_string(tag.title) << "|"
          this_file << make_safe_field_string(tag.album) << "|"

          this_file << make_safe_field_number(tag.track) << "|"
        else
          this_file << "|||0|"
        end

        if !properties.nil?
          this_file << make_safe_field_number(properties.length) << "|"
          this_file << make_safe_field_number(properties.bitrate) << "|"
          this_file << make_safe_field_number(properties.sample_rate) << "|"
        else
          this_file << "0|0|0|"
        end

        this_file << date_now << "|"
        this_file << date_now

      end  # File is automatically closed at block end
    rescue
      #error, I ignore you
      this_file = nil
    end

    file_content << this_file << "\n" unless this_file.nil?
    count = count + 1

    if count % 2340 == 0
      save_file(file_content)
      file_content = ""
    end
    bar.increment!
  end
  save_file(file_content)
end

def save_file(text)
  File.open(BULK_TXT_PATH, "a") {|f|
    f.write text
  }
  puts "#{BULK_TXT_PATH} was wrote."
end

def make_safe_field_string(text)
  text = text.to_s[0..254]
  text = text.gsub(/[\r\n\\\/\|\u0096]/, ", ")
  text
end

def make_safe_field_number(number)
  number = number.to_i.abs
  number = number / 2147483647
  number.to_s
end

desc "import song bulk file to rails database"
task "songs:importbulk" => :environment  do

  if File.exists?(BULK_TXT_PATH)
    CONN = ActiveRecord::Base.connection

    sql = "copy songs(filepath, artist, title, album, tracknumber, length, bitrate, sample_rate, updated_at, created_at) from '#{BULK_TXT_PATH}' with delimiter '|'"
    CONN.execute sql
  end

end
