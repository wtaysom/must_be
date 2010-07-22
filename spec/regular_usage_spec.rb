require 'spec_helper'

describe MustBe, " regular usage" do
  include MustBeExampleHelper
  
  describe "#must_be", " notifies when receiver doesn't case-equal (===) any"\
      " of its arguments" do
    describe "when called with a Class, it notifies unless"\
        " receiver.is_a? Class" do
      example "4.must_be(Numeric) should not notify" do
        4.must_be(Numeric)
        should_not notify
      end
      
      example "4.must_be(Float) should notify" do
        4.must_be(Float)
        should notify("4.must_be(Float), but is Fixnum")
      end
    end
    
    describe "when called with a regexp, it notifies unless"\
        " regexp =~ receiver" do
      example "\"funny\".must_be(/n{2}/) should not notify" do
        "funny".must_be(/n{2}/)
        should_not notify
      end
      
      example "\"funny\".must_be(/\d/) should notify" do
        "funny".must_be(/\d/)
        should notify("\"funny\".must_be(/\\d/), but is String")
      end
    end
    
    describe "when called with a range, it notifies unless"\
        " range.include? receiver" do
      example "5.must_be(1..5) should not notify" do
        5.must_be(1..5)
        should_not notify
      end
      
      example "5.must_be(1...5) should notify" do
        5.must_be(1...5)
        should notify("5.must_be(1...5), but is Fixnum")
      end
    end
    
    describe "when called with an array, it notifies unless"\
        " array == receiver" do
      example("[3, 5].must_be([3, 5]) should not notify") do
        [3, 5].must_be([3, 5])
        should_not notify
      end
      
      example("3.must_be([3, 5]) should notify") do
        3.must_be([3, 5])
        should notify("3.must_be([3, 5]), but is Fixnum")
      end
    end
    
    describe "when called with a lambda, it notifies unless block[receiver]" do
      example ":anything.must_be(lambda {|v| true }) should not notify" do
        :anything.must_be(lambda {|v| true })
        should_not notify
      end
      
      example ":anything.must_be(lambda {|v| false }) should notify" do
        :anything.must_be(lambda {|v| false })
        should notify
      end
    end
    
    describe "when called with most other objects, it notifies unless"\
        " object == receiver" do
      example ":yep.must_be(:yep) should not notify" do
        :yep.must_be(:yep)
        should_not notify
      end
      
      example ":yep.must_be(:nope) should notify" do
        :yep.must_be(:nope)
        should notify(":yep.must_be(:nope), but is Symbol")
      end
    end
    
    describe "when called without arguments, it notifies unless receiver is"\
        " nil or false" do
      example "5.must_be should not notify" do
        5.must_be
        should_not notify
      end
      
      example "nil.must_be should notify" do
        nil.must_be
        should notify("nil.must_be, but is NilClass")
      end
      
      example "false.must_be should notify" do
        false.must_be
        should notify("false.must_be, but is FalseClass")
      end
    end
    
    describe "when called with multiple arguments, it notifies unless receiver"\
        " case-equals (===) one of them" do
      example ":happy.must_be(String, Symbol) should not notify" do
        :happy.must_be(String, Symbol)
        should_not notify
      end
      
      example "934.must_be(String, Symbol) should notify" do
        934.must_be(String, Symbol)
        should notify("934.must_be(String, Symbol), but is Fixnum")
      end
    end    
  end
  
  describe "#must_only_contain" do
    describe "with Array receiver, it should notify unless each item in the"\
        " array case-equals (===) one of the arguments" do
      example "[1, :hi, \"wow\"].must_only_contain(Numeric, Symbol, String)"\
          " should not notify" do
        [1, :hi, "wow"].must_only_contain(Numeric, Symbol, String)
        should_not notify
      end
      
      example "[1, :hi, \"wow\"].must_only_contain(Numeric, String)"\
          " should not notify" do
        [1, :hi, "wow"].must_only_contain(Numeric, String)
        should notify(":hi.must_be(Numeric, String), but is Symbol"\
          " in container [1, :hi, \"wow\"]")
      end
    end
    
    describe "with Hash receiver, it should notify unless each pair"\
        " case-equals (===) a pair in an argument hash" do
      example "{:key => \"value\"}.must_only_contain("\
          "{Symbol => [Symbol, String]}) should not notify" do
        {:key => "value"}.must_only_contain({Symbol => [Symbol, String]})
        should_not notify
      end
      
      example "{:key => \"value\"}.must_only_contain({Symbol => Symbol})"\
          " should notify" do
        {:key => "value"}.must_only_contain({Symbol => Symbol})
        should notify("pair {:key=>\"value\"} does not match"\
          " [{Symbol=>Symbol}] in {:key=>\"value\"}")
      end
    end
  end
  
  #!! other methods? must, must_only_ever_contain, must_notify, must_check, etc. 
  #! must* methods return their receiver
end