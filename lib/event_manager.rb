# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  length = phone_number.length
  if length < 10 || length > 11
    false
  elsif length == 11
    if phone_number[0] == '1'
      phone_number[1..10]
    else
      false
    end
  else
    phone_number
  end
end

def peak_registration_hours(csv_contents)
  hours = Hash.new(0)
  csv_contents.each do |row|
    hour = Time.strptime(row[1], '%D %k').hour
    hours[hour] += 1
  end
  hours
end

def peak_registration_days(csv_contents)
  days = Hash.new(0)
  csv_contents.each do |row|
    day = Date.strptime(row[1], '%D %k').strftime('%A')
    days[day] += 1
  end
  days
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts(form_letter)
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
=begin
contents.each do |row|
  id = row[0]

  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
=end

puts peak_registration_days(contents)