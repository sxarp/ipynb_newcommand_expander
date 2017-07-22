require 'json'
require 'pry'

target = "./technical_note.ipynb"

module Braces
  def self.p(s)
    head = ""
    tail = ""
    raise "The first Character need to be '{'!" unless s[0] == "{"
    stack = 0
    endflag = false

    s.each_char do |c|
     if endflag
       tail << c
       next
     end

      raise "Braces unmatched!" if stack < 0

      case c
      when "{"
        stack += 1
        head << "{"
      when "}"
        stack -= 1
        head << "}"
        endflag = true if stack == 0
      else
        head << c
      end
    end
    raise "Too much '{'s !" if stack > 0

    return [head, tail]
  end
end


File.open(target) do |file|
  counter=0
  binding.pry
  file.each_line do |line|
    counter += 1; break if counter >= 10
    m = /\s*"cell_type":\s"markdown",(.*)/.match line
    binding.pry unless (m || [nil, "nomatch"])[1] 
    puts (m ? "match:" + m[1] +"|"+ line : "nomatch:" + line)
  end
end

puts "end"
