#user prompted "price?"
#user type in price
#program collects price
#program prints subtotal
#user type "done"
#program prints total price
#program validate price
#user prompted "price tendered?"
#program calculate change + conditions


class CashRegister
  attr_accessor :prices, :money_received

  def initialize
    @prices = []
    @money_received = 0.0
  end

  def run
    puts "What is the sale price?"
    price = gets.chomp

    until is_done?(price) do
      if is_valid?(price)
        @prices.push(price.to_f)
        puts "Subtotal: $" + subtotal.to_s + "."
      else
        puts "INVALID PRICE. Please put valid price."
      end
      puts "What is the sale price?"
      price = gets.chomp
    end

    puts "Total: $" + subtotal.to_s + "."

    puts "What is the amount tendered?"
    @money_received = gets.chomp
    while !is_valid?(@money_received) do
      puts "INVALID CHANGE. Please put valid change."
      puts "What is the amount tendered?"
      @money_received = gets.chomp
    end
    @money_received = money_received.to_f
    calculateChange
    initialize # reset the object so that state doesn't carry from one transaction to the next
    puts Time.now.getutc.to_s + " - Transaction complete!"
  end

  def subtotal
    sum = 0
    @prices.each do |price|
      sum = sum + price
    end
    return sum
  end

  def is_done?(input)
    input.downcase == "done"
  end

  def is_valid?(input)
    return !input.match(/\A\d+(\.\d{1,2})?\z/).nil?
  end

  def calculateChange
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
    calculateChange
  end

# c = CashRegister.new
# c.run

#The system will supply the number of quarters, dimes, nickels, and pennies that should be issued for the change due.
#19.66- dollar: 19, quarter: 2, dime: 1, nickel: 1, penny: 1
#10.48- dollar: 10, quarter:1, nickel: 0, dime:2, penny:3

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
    # coins = {dollar: dollar, quarter: quarter, dime: dime, nickel: nickel, penny: penny}
    puts "You should issue:"
    coins.each do |coin, value|
      puts "#{coin}: #{value}"
    end
  end
end
