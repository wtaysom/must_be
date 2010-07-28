require 'spec_helper'

#!!! factor out this notify_example pattern that you use pervasively here -- the eval it a small price to pay

describe MustBe, " typical usage" do
  include MustBeExampleHelper
  
  describe "#must_be", " notifies when receiver doesn't case-equal (===) any"\
      " of its arguments" do
    context "when called with a Class, it notifies unless"\
        " receiver.is_a? Class" do
      example "4.must_be(Numeric) should not notify" do
        4.must_be(Numeric).should == 4
        should_not notify
      end
      
      example "4.must_be(Float) should notify" do
        4.must_be(Float)
        should notify("4.must_be(Float), but is Fixnum")
      end
    end
    
    context "when called with a regexp, it notifies unless"\
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
    
    context "when called with a range, it notifies unless"\
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
    
    context "when called with an array, it notifies unless"\
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
    
    context "when called with a proc, it notifies unless proc[receiver]" do
      example ":anything.must_be(lambda {|v| true }) should not notify" do
        :anything.must_be(lambda {|v| true })
        should_not notify
      end
      
      example ":anything.must_be(lambda {|v| false }) should notify" do
        :anything.must_be(lambda {|v| false })
        should notify
      end
    end
    
    context "when called with most other objects, it notifies unless"\
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
    
    context "when called without arguments, it notifies if receiver is"\
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
    
    context "when called with multiple arguments, it notifies unless receiver"\
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
  
  describe "#must" do
    context "when called with a block, it notifies if the result is"\
        " false or nil" do
      example ":helm.must(\"message\")"\
          " {|receiver, message| message == \"mess\" } should notify" do
        :helm.must("message") {|receiver, message| message == "\"mess\""}
        should notify("message")
      end
      
      example ":helm.must {|receiver| receiver == :helm } should not notify" do
        :helm.must("message") {|receiver| receiver == :helm }
        should_not notify
      end
    end
    
    context "when called with no argument, it returns a proxy which notifies"\
        " when a method returning false or nil is called" do
      subject { 5.must }
        
      example "5.must == 4 should notify" do
        subject == 4
        should notify("5.must.==(4)")
      end
        
      example "5.must > 4 should not notify" do
        subject > 4
        should_not notify
      end
    end
  end
  
  describe "#must_only_contain" do
    context "with Array receiver, it should notify unless each item in the"\
        " array case-equals (===) one of the arguments" do
      example "[1, :hi, \"wow\"].must_only_contain(Numeric, Symbol, String)"\
          " should not notify" do
        [1, :hi, "wow"].must_only_contain(Numeric, Symbol, String)
        should_not notify
      end
      
      example "[1, :hi, \"wow\"].must_only_contain(Numeric, String)"\
          " should notify" do
        [1, :hi, "wow"].must_only_contain(Numeric, String)
        should notify("must_only_contain: :hi.must_be(Numeric, String), but is"\
          " Symbol in container [1, :hi, \"wow\"]")
      end
    end
    
    context "with Hash receiver, it should notify unless each pair"\
        " case-equals (===) a pair in an argument hash" do
      example "{:key => \"value\"}.must_only_contain("\
          "{Symbol => [Symbol, String]}) should not notify" do
        {:key => "value"}.must_only_contain({Symbol => [Symbol, String]})
        should_not notify
      end
      
      example "{:key => \"value\"}.must_only_contain({Symbol => Symbol},"\
          " {Symbol => Numeric}) should notify" do
        {:key => "value"}.must_only_contain({Symbol => Symbol},
          {Symbol => Numeric})
        should notify("must_only_contain: pair {:key=>\"value\"} does not"\
          " match [{Symbol=>Symbol}, {Symbol=>Numeric}] in container"\
          " {:key=>\"value\"}")
      end
    end
  end
  
  describe "#must_only_ever_contain" do
    context "like #must_only_contain, it notifies unless each item"\
        " case-equals (===) one of the arguments" do
      example "[1, :hi, \"wow\"].must_only_ever_contain(Numeric, Symbol,"\
          " String) should not notify" do
        [1, :hi, "wow"].must_only_ever_contain(Numeric, Symbol, String)
        should_not notify
      end

      example "[1, :hi, \"wow\"].must_only_ever_contain(Numeric, String)"\
          " should notify" do
        [1, :hi, "wow"].must_only_ever_contain(Numeric, String)
        should notify("must_only_ever_contain: :hi.must_be(Numeric, String),"\
          " but is Symbol in container [1, :hi, \"wow\"]")
      end
    end
    
    context "it notifies whenever the container is updated to hold an item"\
        " which does not case-equal (===) one of the arguments" do
      describe "[1, 2, 3].must_only_ever_contain(Numeric)" do
        subject { [1, 2, 3].must_only_ever_contain(Numeric) }
      
        it "should not notify if 3.14 is appended" do
          subject << 3.14
          should_not notify
        end
      
        it "notify if nil is appended" do
          subject << nil
          should notify("must_only_ever_contain: Array#<<(nil)\n"\
            "nil.must_be(Numeric), but is NilClass in container [1, 2, 3, nil]")
        end
      end
    end
  end
  
  describe "#must_notify", " primitive used to define other must_be methods" do
    context "when called with a string, it notifies with a string message" do
      example "must_notify(\"message\") should notify" do
        must_notify("message")
        should notify("message")
      end
    end
    
    context "when called with multiple arguments, notifies with method"\
        " invocation details" do
      example "must_notify(:receiver, :method_name, [:arg, :arg, :arg],"\
          " lambda {}, \" additional message\") should notify" do
        must_notify(:receiver, :method_name, [:arg, :arg, :arg],
          lambda {}, " additional message")
        should notify(":receiver.method_name(:arg, :arg, :arg) {} additional"\
          " message")
      end
    end
  end
  
  describe "#must_check", " interrupts normal notification" do
    context "when called with a block, it yields to the block" do
      example "if the block attempts to notify, then #must_check returns"\
          " the note" do
        note = must_check do
          must_notify("message")
        end
        note.message.should == "message"
        should_not notify
      end
      
      example "if the block would not notify, then #must_check returns nil" do
        note = must_check do
          :would_not_notify
        end
        note.should be_nil
        should_not notify
      end
    end
    
    context "when called with a proc and a block, #must_check calls the proc" do
      example "if the proc attempts to notify, then #must_check passes the"\
          " note to the block and notifies with the result of the block" do
        must_check(lambda do
          must_notify("original message")
        end) do |note|
          note.message.should == "original message"
          "new message"
        end
        should notify("new message")
      end
      
      example "if the proc does not notify, then the block is not called" do
        did_call_block = false
        must_check(lambda do
          :would_not_notify
        end) do |note|
          did_call_block = true
        end
        did_call_block.should be_false
      end
    end
  end
end