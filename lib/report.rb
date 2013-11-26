require 'json'
require 'table_print'

class Report
  attr_accessor :data

  BAR = "============================================================="

  def initialize
    get_data
  end

  def get_data
    @file = './assets/transactions.json'
    @data = fetch_data
  end

  def run
    get_data
    puts "Start date (Please enter MM/DD/YYYY):"
    start_dt = validate_date(gets.chomp)
    puts "End date (Please enter MM/DD/YYYY):"
    end_dt = validate_date(gets.chomp)
    puts "Fetching report..."
    print_report(fetch_analytics_range(start_dt, end_dt))
  end

  # @param [String] date - date string passed by user
  # @return [Date] parsed date from user
  def validate_date(date)
    begin
      # parse the date given
      date = Date.strptime(date, '%m/%d/%Y')
      # If the date specified is in the future, alert the user with an error message
      if (date > Date.today)
        puts "Cannot give a date in the future, please enter date in MM/DD/YYYY format:"
        validate_date(gets.chomp)
      end
      return date
    # If the date specified is invalid, alert the user with an error message
    rescue ArgumentError => ex
      if (ex.message == 'invalid date')
        puts "Invalid date specified, please enter date in MM/DD/YYYY format:"
        validate_date(gets.chomp)
      end
    end
  end

  def fetch_data
    data = {} #if you call it again, you reset it so you don't get duplicates
    # for each line in the transactions
    lines = File.readlines(@file)  #returns an array where each value is a line from the transactions.json. the values are strings.

    # remove newline
    lines.map! {|line| line.chomp }
    lines.each do |line|
      # convert string from file into Hash
      parsed_data = JSON.parse(line, {:symbolize_names => true})
      date = Time.at(parsed_data[:time]).strftime('%Y%m%d')
      items = parsed_data[:order]
      order = {time: Time.at(parsed_data[:time]), items: items}
      # set key only if it doesn't exist yet
      data[date] ||= []
      data[date].push(order)
    end
    data
  end

  # @param [Date] date - date to fetch analytics for
  # @return [Array] an array of information for each order for given date
  def fetch_analytics(date)
    # If sales data is found for that range, a well-formatted list of orders is outputted. Each order should include the date the order was completed, the time the order was completed, the total number of items purchased, the gross sales, and the cost of goods involved in that order
    # convert Date object to string for Hash key
    date = date.strftime('%Y%m%d')
    if @data.key?(date)
      orders = []
      analytics = {}
      # If sales data is found for that date, I am informed of the gross sales as well as the net profit. I am also told how many items were sold
      analytics[:gross_sales] = 0.0
      analytics[:net_profit] = 0
      analytics[:total_num_items] = 0

      @data[date].each do |order|
        order_data = {}
        order_data[:date] = order[:time].strftime('%b-%d-%Y')
        order_data[:time] = order[:time].strftime('%H:%M:%S')

        order_data[:total_num_items] = 0
        order_data[:gross_sales] = 0.0
        order_data[:cost] = 0.0

        order[:items].each do |item|
          gross_sale = item[:qty]*item[:price]
          cost = item[:qty]*item[:cost]

          order_data[:total_num_items] += item[:qty]
          order_data[:gross_sales] += gross_sale
          order_data[:cost] += cost
          # update running totals
          analytics[:total_num_items] += item[:qty]
          analytics[:gross_sales] += gross_sale
          analytics[:net_profit] += (gross_sale - cost)
        end
        orders.push(order_data)
      end
      analytics[:orders] = orders
      return analytics
    else
      return nil
    end
  end

  # @param [Date] start_dt - date to start looking for transactions
  # @param [Date] end_dt - date to stop looking for transactions
  # @return [Hash] analytics for the given date range
  def fetch_analytics_range(start_dt, end_dt)
    # build a Range of dates
    # for each date ... call fetch_analytics(date)
    analytics = {}
    (start_dt .. end_dt).each do |date|
      analytics_for_date = fetch_analytics(date)
      if analytics_for_date.nil?
        puts "No data found for: " + date.strftime('%b-%d-%Y')
      else
        analytics[date] = analytics_for_date
      end
    end
    # If sales data is not found for that day, alert the user that no sales data was found
    return analytics
  end

  # @param [Hash] analytics - print the report
  # If sales data is found for that date, I am informed of the gross sales as well as the net profit. I am also told how many items were sold
  # If sales data is found for that date, a well-formatted list of orders is outputted. Each order should include the date the order was completed, the time the order was completed, the total number of items purchased, the gross sales, and the cost of goods involved in that order
  def print_report(analytics)
    analytics.keys.each do |date|
      puts BAR
      puts "=================== Orders for: #{date.strftime('%b-%d-%Y')} ================="
      puts BAR
      tp analytics[date][:orders]
      puts "==================== Totals for: #{date.strftime('%b-%d-%Y')} ================="
      # remove orders key so we can pretty print again
      analytics[date].delete(:orders)
      tp analytics[date]
      puts ""
    end
  end
end
