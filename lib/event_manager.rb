require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require_relative './apikey.rb'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end
def clean_phonenumber(phonenumber)
    return '' if phonenumber.length > 11 || phonenumber.length < 10
    return phonenumber if phonenumber.length == 10
    return phonenumber[1..10] if phonenumber.length == 11 && phonenumber[0] == 1
    ''
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = apikey

    begin
        civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

def popular_hours(dates)
    # extract hours from dates
    hours = dates.map{|date| date.hour}
    # count instances of each hour
    hour_counts = hours.reduce({}) {
        |counts, hour|
        counts[hour].nil? ? counts[hour] = 1 : counts[hour] += 1
        counts
    }
    # return array sorted by instances
    hour_counts
               # Convert to Array
               .to_a
               # sort by instances
               .sort {|a,b| b[1] <=> a[1]}
               # return only hours in sorted form
               .map {|count| count[0]}
end

def most_popular_hour(dates)
    popular_hours(dates)[0]
end

def popular_days(dates)
    days = dates.map{|date| date.strftime('%A')}
    day_counts = days.reduce({}) {
        |counts, day|
        counts[day].nil? ? counts[day] = 1 : counts[day] += 1
        counts
    }
    day_counts
              .to_a
              .sort{|a,b| b[1] <=> a[1]}
              .map {|count| count[0]}
end

def most_popular_day(dates)
    popular_days(dates)[0]
end

puts 'EventManager Initialized!'

contents = CSV.open(
    'event_attendees.csv', 
    headers: true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
dates = []

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    date = Time.strptime(row[:regdate], "%m/%d/%y %H:%M")
    dates += [date]

    zipcode = clean_zipcode(row[:zipcode])

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)
end

puts "The most popular hours is #{most_popular_hour(dates)}"
puts "The most popular day is #{most_popular_day(dates)}"