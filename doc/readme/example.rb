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
2.must_be_close(2.1)
#=> 2.must_be_close(2.1, 0.1), difference is 0.1

2.must_be_close(2.1, 6)
2.must_be_close(9.0, 6)
#=> 2.must_be_close(9.0, 6), difference is 7.0

# must_be uses case (===) equality.
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

## `Module#attr_typed`

class Typed
  attr_typed :v, Symbol
  attr_typed :n, Fixnum, Bignum
end

t = Typed.new
t.v = :hello
t.v = "world"
#=> attribute `v' must be a Symbol, but value "world" is a String

t.n = 411
t.n = 4.1
#=> attribute `n' must be a Fixnum or Bignum, but value 4.1 is a Float

## Containers

#!!
#must_only_contain
#must_not_contain
#must_only_ever_contain
#must_never_ever_contain

## Proxy

#!!
#must {}
#must ==
#must >
#must even?

#must_not {}
#must_not ==
#must_not <
#must_not odd?

## Core

#must_notify(string)
#must_notify(object, message, args, block, other message)
#must_notify(note)

#must_check {}
#must_check(proc) {}

## Nonstandard Control Flow

#!!
#must_raise(Error, /match/) {}
#must_not_raise {}
#must_throw()
#must_not_throw(:this, "object") {}