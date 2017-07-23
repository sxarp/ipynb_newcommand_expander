require 'json'
require 'pry'

target = "./technical_note.ipynb"

class Test
  def run
    counter = 0
    succseed_flag = true
    self.methods.grep(/test_/).each do |test|
      counter += 1
      begin
        self.send test
      rescue => e
        succseed_flag = false
        puts "Failed!!: #{test.to_s[5..-1]}"
        puts e
      else
        print '.' 
      end
    end

    print "#{counter} tests passed!" if succseed_flag 
  end

  def assert(tf, message = 'Assertion failed!')
    raise message unless tf
  end
end

module Braces
  def self.parse(s)
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
      h, tail = self.parse tail
      args << h[1..-2]
    end

    [args, tail]
  end
end

class Newcommand

  attr_accessor :name, :arg_num, :expr

  def create(sequence)

    m = /\\newcommand{\\([^}]+)}(\[[0-9]+\]|)({.*)/.match sequence

    raise "Invalid newcommand definition!" unless m

    @name=m[1]
    @arg_num= m[2].length == 0 ? 0 : /\[([0-9]+)\]/.match(m[2])[1].to_i
    @expr, sequence = Braces.p m[3]

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
    m=/^(.*?)\\#{@name}([^a-z].*|)$/.match @tail
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
    if arg_num > 0
      args, @tail = Braces.p @tail
    else
      args = []
    end
    @head << (1..arg_num).to_a.zip(args).reduce(@expr){|expr, arg| expr.gsub("##{arg[0]}", arg[1])}
  end
end

class Test
  
  def test_create_new_command_argzero
    nc = Newcommand.new
    nc.create '\\newcommand{\\mr}{\\mathrm}'
    
    assert nc.name=='mr'
    assert nc.arg_num==0
    assert nc.expr=='\\mathrm'
  end
 
  def test_create_new_command_arg2
    nc = Newcommand.new
    nc.create '\\newcommand{\\diff}[2]{\\frac{\\mr{d}#1}{\\mr{d}#2}}'
    
    assert nc.name=='diff', 'name is wrong'
    assert nc.arg_num==2, 'argnum is wrong'
    assert nc.expr=='\\frac{\\mr{d}#1}{\\mr{d}#2}' , 'expr is wrong'
  end



  def test_new_commad_expand_arg0
    nc = Newcommand.new
    nc.create '\\newcommand{\\mr}{\\mathrm}'

    assert (nc.expand "\\mr") == "\\mathrm", 'ccccccccccccc'
    assert (nc.expand "\\mr \\mr") == "\\mathrm \\mathrm", 'bbbbbbbbbb'
  end

  def test_owari 
  end

end

Test.new.run

File.open(target) do |file|

  counter=0
  file.each_line do |line|
    counter += 1; break if counter >= 10
    m = /\s*"cell_type":\s"markdown",(.*)/.match line
    binding.pry unless (m || [nil, "nomatch"])[1] 
    puts (m ? "match:" + m[1] +"|"+ line : "nomatch:" + line)
  end
end

puts "end"
