require 'json'
require 'pry'

target = "./technical_note.ipynb"

class Test
  def run(opt=nil)

    prefix = opt ? /^#{opt}_/ : /^test_/ 
    counter = 0
    succseed_flag = true
    self.methods.grep(prefix).each do |test|
      counter += 1
      begin
        self.send test
      rescue => e
        succseed_flag = false
        puts "Failed!!: #{test.to_s}"
        puts e
      else
        print '.' 
      end
    end

    print " #{counter} tests passed!" if succseed_flag 
  end

  def assert(tf, message = 'Assertion failed!')
    raise message unless tf
  end

  def eq(lht, rht, message = 'Not equal!')
    raise "#{message} \nlht is #{lht}\nwhile rht is #{rht}" unless lht==rht
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
      args, @tail = Braces.p @tail, @arg_num
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
    
    eq nc.name, 'mr'
    eq nc.arg_num, 0
    eq nc.expr, '\\mathrm'
  end
 
  def test_create_new_command_arg2
    nc = Newcommand.new
    nc.create '\\newcommand{\\diff}[2]{\\frac{\\mr{d}#1}{\\mr{d}#2}}'
    
    eq nc.name, 'diff', 'name is wrong'
    eq nc.arg_num, 2, 'argnum is wrong'
    eq nc.expr, '\\frac{\\mr{d}#1}{\\mr{d}#2}' , 'expr is wrong'
  end

  def test_new_commad_expand_arg0
    nc = Newcommand.new
    nc.create '\\newcommand{\\mr}{\\mathrm}'

    eq (nc.expand "\\mr"), "\\mathrm"
    eq (nc.expand "\\mr \\mr"), "\\mathrm \\mathrm"
    eq (nc.expand "\\mrr \\mr"), "\\mrr \\mathrm"
  end

  def test_new_command_expand_arg2
    nc = Newcommand.new
    nc.create '\\newcommand{\\diff}[2]{\\frac{\\mr{d}#1}{\\mr{d}#2}}'

    eq (nc.expand "\\diff{y}{x}"), "\\frac{\\mr{d}y}{\\mr{d}x}"
    eq (nc.expand " \\diff{y}{x} aaa"), " \\frac{\\mr{d}y}{\\mr{d}x} aaa"
    eq (nc.expand " \\diff{y}{x} \\diff{f}{z}"), " \\frac{\\mr{d}y}{\\mr{d}x} \\frac{\\mr{d}f}{\\mr{d}z}"
    eq (nc.expand " \\diff{y}{x} \\difff{f}{z}"), " \\frac{\\mr{d}y}{\\mr{d}x} \\difff{f}{z}"
  end
end

class RegexStateMachine
  attr_accessor :state

  def initialize(ini_state, state_transition)
    @state=ini_state
    @transition=state_transition
  end

  def evolve(str)
    reg, next_state = @transition[@state]
    raise "next state of #{@state} undetermind!" unless reg && next_state
    @state = next_state if reg.match str
  end
end

class Test
  def wip_state_machine
    rst = RegexStateMachine.new :a, a: [/b/, :b], b: [/c/, :c], c: [/a/, :a]

    eq rst.state, :a
    rst.evolve 'b'
    eq rst.state, :b
    rst.evolve 'x'
    eq rst.state, :b
    rst.evolve 'c'
    eq rst.state, :c
    rst.evolve 'a'
    eq rst.state, :a
  end
end

Test.new.run 'wip'

File.open(target) do |file|

  counter=0
  file.each_line do |line|
    counter += 1; break if counter >= 30
    m = /\s*"cell_type":\s"markdown",(.*)/.match line
    binding.pry unless (m || [nil, "nomatch"])[1] 
    puts (m ? "match:" + m[1] +"|"+ line : "nomatch:" + line)
  end
end

puts "end"
