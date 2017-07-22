require 'json'
require 'pry'

target = "./technical_note.ipynb"

module Braces
  def parse(s)
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

    [head, tail]
  end

  def self.p(s, num=1)
    args = num==1 ? "" : []
    tail = s
    num.times do
      h, tail = parse tail
      args << h[1..-2]
    end

    [args, tail]
  end
end

class Newcommand
  def create(sequence)

    m = /\\newcommand{\\(.+)}(.*)/.match sequence
    @name=m[1]
    sequence=m[2]

    raise "Invalid newcommand definition!" unless m

    m = /\[([0-9]+)\](.*)/.match sequence
    @arg_num=(m || [])[1].to_i
    sequence = (m || [])[2] || sequence

    raise "Invalid newcommand definition!" unless m

    @expr, sequence = Braces.p sequence
    sequence
  end

  def initialize(name=nil, arg_num=nil, expr=nil)
    @name=name; @arg_num=arg_num; @expr=expr
  end

  def expand(sequence)
    @head=""
    @tail=sequence
    while find
     expand_tail
    end
    @head
  end

  private
  def find
    m=/(.*)\\#{@name}(.*)/.match @tail
    if m
      @head << m[1]
      @tail=m[2]
      true
    else
      @head << @tail
      false
    end
  end

  def expand_tail
    args, @tail = Braces.p @tail
    @head << (1..arg_num).to_a.zip(args).reduce(@expr){|expr, arg| expr.gsub("##{arg[0]}", arg[1])}
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
