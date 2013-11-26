#user prompted "price?"
#user type in price
#program collects price
#program prints subtotal
#user type "done"
#program prints total price
#program validate price
#user prompted "price tendered?"
#program calculate change + conditions
#program count coins

require 'csv'
require 'pry'
require 'json'
require './lib/report.rb'

class CashRegister
  def initialize
    @trans_file = './assets/transactions.json'
    @product_catalog = init_product_catalog
    @report = Report.new

    @money_received = 0.0
    @qty = init_qty
  end

  def init_qty
    qty = {}
    @product_catalog.keys.each do |k|
      qty[k] = 0
    end
    return qty
  end

  def init_product_catalog
    product_catalog = {}
    csv = CSV.table("./assets/product_catalog.csv")
    headers = csv.headers
    products = csv.to_a
    # remove header from collection
    products.delete_at(0)
    products.each do |product|
      # assume the first entry is ALWAYS ID
      # convert all values in csv to their k/v pairs
      product_catalog[product[0].to_s] = Hash[headers.zip(product)]
    end
    product_catalog
  end

  def run(is_open = true)
    if is_open
      is_done = false
      until is_done do
        puts "Please enter ID number."
        id = gets.chomp
        if is_done?(id)
          is_done = true
        else
          id = validate_id(id)
          puts "Please enter quantity"
          qty = validate_qty(gets.chomp)
          @qty[id] = @qty[id] + qty
        end
      end

      #puts summary of all items bought and their quantity and the total $.
      @product_catalog.each do |id, prod_info|
        puts "#{prod_info[:name]} #{@qty[id]}"
      end
      puts "Total: $" + subtotal.to_s + "."

      puts "What is the amount tendered?"
      @money_received = gets.chomp
      while !is_valid?(@money_received) do
        puts "INVALID CHANGE. Please put valid change."
        puts "What is the amount tendered?"
        @money_received = gets.chomp
      end
      @money_received = @money_received.to_f
      calculate_change
      puts Time.now.getutc.to_s + " - Transaction complete!"
      store_transaction
      reset
      register_prompt
    end
  end

  def register_prompt
    puts "Type 'close' to close register or 'enter' to continue or 'report' to generate report."
    action = gets.chomp
    if action == 'close'
      is_open = false
      run(is_open)
    elsif action == 'report'
      @report.run
      register_prompt
    else
      run
    end
  end

  def reset
    @qty = init_qty
    @money_received = 0.0
  end

  def validate_id(id)
    while !@product_catalog.keys.include?(id)
      puts "Invalid product id."
      puts "Please enter ID number."
      id = gets.chomp
    end
    return id
  end

  def validate_qty(qty)
    while !qty.match(/\A\d+\z/)
      puts "Invalid quantity. Please enter valid quantity."
      qty = gets.chomp
    end
    return qty.to_i
  end

  def subtotal
    sum = 0
    @qty.each do |id, qty|
      price = @product_catalog[id][:price]
      sum = sum + qty * price
    end
    return sum
  end

  def is_done?(input)
    input.downcase == "done"
  end

  def is_valid?(input)
    return !input.match(/\A\d+(\.\d{1,2})?\z/).nil?
  end

  def calculate_change
    change = @money_received - subtotal
    if change == 0
      puts "Exact amount tendered. Thank you!"
    elsif change > 0
      puts "Your change is" + " $#{change}"
      coins = calculate_coins(change)
      print_coins(coins)
    else
      not_enough_money(change)
    end
  end

  def not_enough_money(change)
    while subtotal > @money_received
      puts "WARNING: Customer still owes " + "$#{change.abs.to_s}."
      puts "Total: $" + subtotal.to_s + "."
      puts "What is the amount tendered?"
      @money_received = gets.chomp

      while !is_valid?(@money_received) do
        puts "INVALID CHANGE. Please put valid change."
        puts "What is the amount tendered?"
        @money_received = gets.chomp
      end
      @money_received = @money_received.to_f
      change = @money_received - subtotal
    end
    calculate_change
  end

  def calculate_coins(change)
    coin_values = {dollar: 100, quarter: 25, dime: 10, nickel: 5, penny: 1}
    num_of_pennies= (change * 100).to_i

    dollar = num_of_pennies/coin_values[:dollar]
    remainder  = num_of_pennies%coin_values[:dollar]
    quarter = remainder/coin_values[:quarter]
    remainder = remainder%coin_values[:quarter]
    dime = remainder/coin_values[:dime]
    remainder = remainder%coin_values[:dime]
    nickel = remainder/coin_values[:nickel]
    remainder = remainder%coin_values[:nickel]
    penny = remainder/coin_values[:penny]
    return {dollar: dollar, quarter: quarter, dime: dime, nickel: nickel, penny: penny}
  end

  def print_coins(coins)
    puts "You should issue:"
    coins.each do |coin, value|
      puts "#{coin}: #{value}"
    end
  end

  def store_transaction
    # find only the items purchases
    products_purchased = @qty.reject {|k,v| v == 0}
    transactions = []
    products_purchased.each do |k,v|
      transactions.push({
        id: k,
        qty: v,
        sku: @product_catalog[k][:sku],
        price: @product_catalog[k][:price],
        cost: @product_catalog[k][:cost]
        }
      )
    end

    order_data = {order: transactions, time: Time.new.to_i}

    write_transaction(order_data)
  end

  def write_transaction(t)
    File.open(@trans_file, 'a+') do |file|
      file.write(t.to_json+"\n") #convert each transaction to json
    end
  end
end

c = CashRegister.new
c.run
