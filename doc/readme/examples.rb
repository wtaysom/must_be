## Basic

87.must_be_a(Float, Integer)
87.must_be_a(Symbol, String)
#=> 87.must_be_a(Symbol, String), but is a Fixnum

87.must_not_be_a(Symbol, String, "message")
87.must_not_be_a(Float, Integer, "message")
#=> 87.must_not_be_a(Float, Integer, "message"), but is a Fixnum

2.must_be_in(1, 2, 3)
2.must_be_in([1, 2, 3])
2.must_be_in(1 => 3, 2 => 4)
2.must_be_in(1..3)
2.must_be_in
#=> 2.must_be_in

2.must_not_be_in
2.must_not_be_in(4, 5)
2.must_not_be_in(1 => 3, 2 => 4)
#=> 2.must_not_be_in({1=>3, 2=>4})

true.must_be_boolean
false.must_be_boolean
nil.must_be_boolean
#=> nil.must_be_boolean

2.must_be_close(2.0)
2.must_be_close(2.01)
2.must_be_close(2.25)
#=> 2.must_be_close(2.25, 0.1), difference is 0.25

2.must_be_close(2.1, 6)
2.must_be_close(9.0, 6)
#=> 2.must_be_close(9.0, 6), difference is 7.0

34.must_be(Integer, :all)
:all.must_be(Integer, :all)
:none.must_be(Integer, :all)
#=> :none.must_be(Integer, :all), but matches Symbol

5.must_be(1..5)
5.must_be(1...5)
#=> 5.must_be(1...5), but matches Fixnum

5.must_not_be(1...5)
3.must_not_be(1...5)
#=> 3.must_not_be(1...5), but matches Fixnum

true.must_be
nil.must_be
#=> nil.must_be, but matches NilClass
false.must_be
#=> false.must_be, but matches FalseClass

nil.must_not_be
:hello.must_not_be
#=> :hello.must_not_be, but matches Symbol

:yep.must_be(lambda {|v| v == :yep})
:nope.must_be(lambda {|v| v == :yep})
#~> :nope.must_be\(#<Proc:0x[^.]+?>\), but matches Symbol

:yep.must_not_be(lambda {|v| v == :nope})
:nope.must_not_be(lambda {|v| v == :nope})
#~> :nope.must_not_be\(#<Proc:0x[^.]+?>\), but matches Symbol

## Proxy

7.must {|x| x > 3}
7.must {|x| x < 3}
#=> 7.must {}

7.must_not {|x| x < 3}
7.must_not {|x| x > 3}
#=> 7.must_not {}

7.must == 7
7.must > 3
7.must.even?
#=> 7.must.even?

7.must_not == 8
7.must_not < 3
7.must_not.odd?
#=> 7.must_not.odd?

## `Module#attr_typed`

class Typed
  attr_typed :v, Symbol
  attr_typed :n, Fixnum, Bignum
  attr_typed :o, &:odd?
end

t = Typed.new
t.v = :hello
t.v = "world"
#=> attribute `v' must be a Symbol, but value "world" is a String

t.n = 411
t.n = 4.1
#=> attribute `n' must be a Fixnum or Bignum, but value 4.1 is a Float

t.o = 7
t.o = 8
#=> attribute `o' cannot be 8

## Containers

["okay", :ready, "go"].must_only_contain(Symbol, String)
["okay", :ready, 4].must_only_contain(Symbol, String)
#=> must_only_contain: 4.must_be(Symbol, String), but matches Fixnum in container ["okay", :ready, 4]

["okay", :ready, "go"].must_not_contain(Numeric)
["okay", :ready, 4].must_not_contain(Numeric)
#=> must_not_contain: 4.must_not_be(Numeric), but matches Fixnum in container ["okay", :ready, 4]

[].must_only_contain(:yes, :no)
[:yep].must_only_contain(:yes, :no)
#=> must_only_contain: :yep.must_be(:yes, :no), but matches Symbol in container [:yep]

[].must_not_contain(:yes, :no)
[:yes, :no].must_not_contain(:yes, :no)
#=> must_not_contain: :yes.must_not_be(:yes, :no), but matches Symbol in container [:yes, :no]

[0, [], ""].must_only_contain
[nil].must_only_contain
#=> must_only_contain: nil.must_be, but matches NilClass in container [nil]

[nil, false].must_not_contain
[0].must_not_contain
#=> must_not_contain: 0.must_not_be, but matches Fixnum in container [0]

{:welcome => :home}.must_only_contain(Symbol => Symbol)
{:symbol => :s, :fixnum => 5}.must_only_contain(Symbol => [Symbol, Fixnum])
{5 => :s, 6 => 5, :t => 5, :s => :s}.must_only_contain([Symbol, Fixnum] => [Symbol, Fixnum])
{6 => 5}.must_only_contain(Symbol => Fixnum, Fixnum => Symbol)
#~> must_only_contain: pair \{6=>5\} does not match .* in container \{6=>5\}

{:welcome => nil}.must_not_contain(nil => Object)
{nil => :welcome}.must_not_contain(nil => Object)
#=> must_not_contain: pair {nil=>:welcome} matches [{nil=>Object}] in container {nil=>:welcome}

{:welcome => :home}.must_only_contain
{:welcome => nil}.must_only_contain
#=> must_only_contain: pair {:welcome=>nil} does not match [] in container {:welcome=>nil}

{nil => false, false => nil}.must_not_contain
{nil => 0}.must_not_contain
#=> must_not_contain: pair {nil=>0} matches [] in container {nil=>0}

numbers = [].must_only_ever_contain(Numeric)
numbers << 3
numbers << :float
#=> must_only_ever_contain: Array#<<(:float): :float.must_be(Numeric), but matches Symbol in container [3, :float]

financials = [1, 4, 9].must_never_ever_contain(Float)
financials.map!{|x| Math.sqrt(x)}
#=> must_never_ever_contain: Array#map! {}: 3.0.must_not_be(Float), but matches Float in container [1.0, 2.0, 3.0]

## MustBe::MustOnlyEverContain.register

class Box  
  attr_accessor :contents
  
  def self.[](contents = nil)
    new(contents)
  end
  
  def initialize(contents = nil)
    @contents = nil
  end
  
  def each
    yield(contents) unless contents.nil?
  end
  
  def empty!
    self.contents = nil
  end
  
  def inspect
    "Box[#{contents.inspect}]"
  end
end

MustOnlyEverContain.register(Box) do
  def contents=(contents)
    must_check_member(contents)
    super
  end
  
  must_check_contents_after :empty!
end

box = Box[:hello].must_only_ever_contain(Symbol)
box.contents = :world
box.contents = 987
#=> must_only_ever_contain: Box#contents=(987): 987.must_be(Symbol), but matches Fixnum in container Box[987]

box = Box[2].must_never_ever_contain(nil)
box.contents = 64
box.empty!
#=> must_never_ever_contain: Box#empty!: nil.must_not_be(nil), but matches NilClass in container Box[nil]

## Core

must_notify("message")
#=> message

must_notify(:receiver, :method, [:args], nil, ", additional message")
#=> :receiver.method(:args), additional message

note = MustBe::Note.new("message")
must_notify(note)
#=> message

note = must_check {}
note.must == nil

note = must_check { :it.must_not_be }
must_notify(note)
#=> :it.must_not_be, but matches Symbol

def add_more_if_notifies
  must_check(lambda do
    yield
  end) do |note|
    MustBe::Note.new(note.message+" more")
  end
end

result = add_more_if_notifies { 5 }
result.must == 5

add_more_if_notifies { must_notify("learn") }
#=> learn more

## Nonstandard Control Flow

def rescuing
  yield
rescue
  raise if $!.is_a? MustBe::Note
end

rescuing { must_raise(/match/) { raise ArgumentError, "should match" } }
must_raise { "But it doesn't!" }
#=> main.must_raise {}, but nothing was raised

must_not_raise { "I'm fine."}
rescuing { must_not_raise { raise } }
#=> main.must_not_raise {}, but raised RuntimeError

catch(:ball) { must_throw { throw :ball } }
catch(:ball) { must_throw(:party) { throw :ball } }
#=> main.must_throw(:party) {}, but threw :ball

catch(:ball) { must_not_throw(:ball, :fiercely) { throw :ball, :gently } }
catch(:ball) { must_not_throw { throw :ball } }
#=> main.must_not_throw {}, but threw :ball