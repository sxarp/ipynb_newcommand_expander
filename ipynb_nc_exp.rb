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

module CSG_Expander
  def self.apply(sentence, matcher, &block)
    m = /(^.*?)(#{matcher.inspect[1..-2]}.*)/.match sentence
    m ? self.apply(m[1] + block.call(m[2]), matcher, &block) : sentence
  end
end

class Newcommand

  attr_accessor :name, :arg_num, :expr

  def create(sequence)

    m = /\\\\newcommand{\\\\([^}]+)}(\[[0-9]+\]|)({.*)/.match sequence

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
    CSG_Expander.apply sequence, /\\\\#{@name}([^a-z].*|$)/ do |seq|
      m = /\\\\#{@name}(.*)/.match seq
      if @arg_num > 0
        args, tail = Braces.p m[1], @arg_num
      else
        args = []; tail = m[1]
      end
      (1..@arg_num).to_a.zip(args).reduce(@expr){|expr, arg| expr.gsub("##{arg[0]}", arg[1])} + tail
    end
  end
end

class Test

  def test_create_new_command_argzero
    nc = Newcommand.new
    nc.create '\\\\newcommand{\\\\mr}{\\\\mathrm}'

    eq nc.name, 'mr'
    eq nc.arg_num, 0
    eq nc.expr, '\\\\mathrm'
  end

  def test_create_new_command_arg2
    nc = Newcommand.new
    nc.create '\\\\newcommand{\\\\diff}[2]{\\\\frac{\\\\mr{d}#1}{\\\\mr{d}#2}}'

    eq nc.name, 'diff', 'name is wrong'
    eq nc.arg_num, 2, 'argnum is wrong'
    eq nc.expr, '\\\\frac{\\\\mr{d}#1}{\\\\mr{d}#2}' , 'expr is wrong'
  end

  def test_new_commad_expand_arg0
    nc = Newcommand.new
    nc.create '\\\\newcommand{\\\\mr}{\\\\mathrm}'

    eq (nc.expand '\\\\mr'), '\\\\mathrm'
    eq (nc.expand "\\\\mr \\\\mr"), "\\\\mathrm \\\\mathrm"
    eq (nc.expand "\\\\mrr \\\\mr"), "\\\\mrr \\\\mathrm"
  end

  def test_new_command_expand_arg2
    nc = Newcommand.new
    nc.create '\\\\newcommand{\\\\diff}[2]{\\\\frac{\\\\mr{d}#1}{\\\\mr{d}#2}}'

    eq (nc.expand "\\\\diff{y}{x}"), "\\\\frac{\\\\mr{d}y}{\\\\mr{d}x}"
    eq (nc.expand " \\\\diff{y}{x} aaa"), " \\\\frac{\\\\mr{d}y}{\\\\mr{d}x} aaa"
    eq (nc.expand " \\\\diff{y}{x} \\\\diff{f}{z}"), " \\\\frac{\\mr{d}y}{\\\\mr{d}x} \\\\frac{\\\\mr{d}f}{\\\\mr{d}z}"
    eq (nc.expand " \\\\diff{y}{x} \\\\difff{f}{z}"), " \\\\frac{\\\\mr{d}y}{\\\\mr{d}x} \\\\difff{f}{z}"
  end
end

class RegexStateMachine
  attr_accessor :state

  def initialize(initial_state, state_transition)
    @state = initial_state
    @transition = state_transition
  end

  def evolve(str)
    candidates = @transition[@state]
    raise "next state of #{@state} undetermind!" unless candidates
    @state = candidates.select{|state, reg| reg.match str}.keys.first || @state
  end
end

class Test
  def test_state_machine2
    rst = RegexStateMachine.new :a, a: {b: /b/}, b: {c: /c/}, c: {a: /a/}

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

class Test
  def test_state_machine3
    rst = RegexStateMachine.new :a, a: {b: /b/, c: /c/}, b: {c: /c/, a: /a/}, c: {a: /a/}

    eq rst.state, :a
    rst.evolve 'c'
    eq rst.state, :c
    rst.evolve 'x'
    eq rst.state, :c
    rst.evolve 'a'
    eq rst.state, :a
    rst.evolve 'b'
    eq rst.state, :b
    rst.evolve 'a'
    eq rst.state, :a

  end
end


class Markdown
  def initialize(input_file)
    @inputfile=input_file
    read
    @cell_finder=RegexStateMachine.new :init, init: {meta_data: /^.*"cell_type":.*"markdown".*/}, meta_data: {source: /.*metadata.*/},
      source: {just_before: /.*source.*/}, just_before: {markdown: /.*/}, markdown: {init: /^[^"]*\][^"]*/}
  end

  def read
    @data = []
    File.open(@inputfile) do |file|
      file.each_line do |line|
        @data << line
      end
    end
  end

  def save output_file
    File.open(output_file, 'w'){|file| @data.each{|line| file.puts(line)}}
  end

  def edit
    @data.map! do |line|
      @cell_finder.evolve line
      if @cell_finder.state == :markdown
        m = /^([^"]*")(.*)(\\n",|"\n)$/.match line
        m[1]+yield(m[2]).to_s+m[3]
      else
        line
      end
    end
    self
  end
end

class Latex < Markdown

  def edit
    math_finder = RegexStateMachine.new :text, text: {doller: /\$/}, doller: {inline: /^[^\$].*/, ddoller: /\$/},
      ddoller: {enviroment: /[^\$].*/, invalid: /^\$.*/}, inline: {text: /\$/}, enviroment: {close_doller: /\$/},
      close_doller: {text: /\$/, invalid: /[^\$].*/}
    super do |tail|
      result = ''
      until tail == '' do
        m = /^([^\$]*)(.*)$/.match tail
        m = /^(.)(.*)$/.match tail if m[1] == ''
        head, tail = m[1], m[2]
        math_finder.evolve head
        result << (([:inline, :enviroment].include? math_finder.state) ? (yield head) : head)
      end
      result
    end
  end
end

class Array
  def expand sentence
    reduce(sentence){|sen, nc| nc.expand(sen)}
  end
end

def main input_file, output_file
  if input_file == output_file
    puts "Are you sure to overwrite #{input_file}?"
    puts "Put 'ok' to proceed."
    answer = STDIN.gets.chomp
    unless answer == 'ok'
      puts 'Aborted.'
      return
    else
      puts 'proceed'
    end
  end
  newcommand_defs = []
  Latex.new(input_file).edit do |tail|
    result = ''
    until tail == '' do
      m = /(.*?)(\\\\newcommand.*)/.match tail
      break unless m
      result << newcommand_defs.expand(m[1])
      tail = m[2]
      nc = Newcommand.new
      tail = nc.create tail
      result << "{}"
      newcommand_defs.unshift nc
    end 
    result + newcommand_defs.expand(tail)
  end.save(output_file)

  puts "Wrote to #{output_file}"
end

#Test.new.run

main ARGV[0], ARGV[1]
