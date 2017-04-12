require_relative 'enrollment'
require_relative 'csv_parser'
require 'pry'

class EnrollmentRepository
  include CSVParser
  attr_reader :data

  def initialize
    @data = []
  end

  def load_data(args)
    added_districts = []
    args[:enrollment].each do |category, file|
      contents = parse_file(file)
      added_districts = added_districts + process_data(contents, category)
    end
    added_districts.uniq
  end

  def process_data(contents, category)
    data_category = translate_category(category)
    contents.map do |row|
      process_row(row, data_category)
    end
  end

  def process_row(row, data_category)
    sanitize(row)
    enrollment_data = make_enrollment_data(row, data_category)
    enrollment = find_by_name(row[:location])
    populate_data(row, enrollment_data, enrollment)
  end

  def find_by_name(name)
    data.find { |enrollment| enrollment.name == name }
  end

  def create_enrollment(enrollment_data)
    data << Enrollment.new(enrollment_data)
  end

  private

  def sanitize(row)
    row[:location] = row[:location].upcase
    row[:data] = format_percent(row[:data]) if row[:dataformat] == "Percent"\
  end

  def populate_data(row, enrollment_data, enrollment)
    if enrollment
      enrollment.update_data(enrollment_data)
    else
      create_enrollment(enrollment_data)
    end
    row[:location]
  end

  def translate_category(category)
    categories = {
      kindergarten: :kindergarten_participation
    }
    categories[category] || category
  end

  def make_enrollment_data(row, data_category)
    { :name => row[:location],
      data_category => {row[:timeframe].to_i => row[:data]} }
  end
end
