require 'spec_helper'

describe MustBe, " typical usage" do
  include MustBeExampleHelper
  
  describe '#must_be', " notifies when receiver doesn't case-equal (===) any"\
      " of its arguments" do
    context "when called with a Class, it notifies unless"\
        " receiver.is_a? Class" do
      notify_example %{4.must_be(Numeric)}
      notify_example %{4.must_be(Float)}, Fixnum
    end
    
    context "when called with a regexp, it notifies unless"\
        " regexp =~ receiver" do
      notify_example %{"funny".must_be(/n{2}/)}
      notify_example %{"funny".must_be(/\d/)}, String
    end
    
    context "when called with a range, it notifies unless"\
        " range.include? receiver" do
      notify_example %{5.must_be(1..5)}
      notify_example %{5.must_be(1...5)}, Fixnum
    end
    
    context "when called with an array, it notifies unless"\
        " array == receiver" do
      notify_example %{[3, 5].must_be([3, 5])}
      notify_example %{3.must_be([3, 5])}, Fixnum
    end
    
    context "when called with a proc, it notifies unless proc[receiver]" do
      notify_example %{:anything.must_be(lambda {|v| true })}
      notify_example %{:anything.must_be(lambda {|v| false })}, true
    end
    
    context "when called with most other objects, it notifies unless"\
        " object == receiver" do
      notify_example %{:yep.must_be(:yep)}
      notify_example %{:yep.must_be(:nope)}, Symbol
    end
    
    context "when called without arguments, it notifies if receiver is"\
        " false or nil" do
      notify_example %{5.must_be}
      notify_example %{nil.must_be}, NilClass
      notify_example %{false.must_be}, FalseClass
    end
    
    context "when called with multiple arguments, it notifies unless receiver"\
        " case-equals (===) one of them" do
      notify_example %{:happy.must_be(String, Symbol)}
      notify_example %{934.must_be(String, Symbol)}, Fixnum
    end
  end
  
  describe '#must' do
    context "when called with a block, it notifies if the result is"\
        " false or nil" do
      notify_example %{:helm.must("message") {|receiver, message| message ==
        "mess" }}, "message"
      notify_example %{:helm.must {|receiver| receiver == :helm }}
    end
    
    context "when called with no argument, it returns a proxy which notifies"\
        " when a method returning false or nil is called" do
      notify_example %{5.must == 4}, "5.must.==(4)"
      notify_example %{5.must > 4}
    end
  end
  
  describe '#must_only_contain' do
    context "with Array receiver, it should notify unless each member in the"\
        " array case-equals (===) one of the arguments" do
      notify_example %{[1, :hi, "wow"].must_only_contain(Numeric, Symbol,
        String)}
      notify_example %{[1, :hi, "wow"].must_only_contain(Numeric, String)},
        "must_only_contain: :hi.must_be(Numeric, String), but is Symbol in"\
          " container [1, :hi, \"wow\"]"
    end
    
    context "with Hash receiver, it should notify unless each pair"\
        " case-equals (===) a pair in an argument hash" do
      notify_example %{{:key => "value"}.must_only_contain({Symbol => [Symbol,
        String]})}
      notify_example %{{:key => "value"}.must_only_contain({Symbol => Symbol},
        {Symbol => Numeric})}, "must_only_contain: pair {:key=>\"value\"} does"\
          " not match [{Symbol=>Symbol}, {Symbol=>Numeric}] in container"\
          " {:key=>\"value\"}"
    end
  end
  
  describe '#must_only_ever_contain' do
    context "like #must_only_contain, it notifies unless each member"\
        " case-equals (===) one of the arguments" do
      notify_example %{[1, :hi, "wow"].must_only_ever_contain(Numeric, Symbol,
        String)}
      notify_example %{[1, :hi, "wow"].must_only_ever_contain(Numeric, String)},
        "must_only_ever_contain: :hi.must_be(Numeric, String), but is Symbol"\
          " in container [1, :hi, \"wow\"]"
    end
    
    context "it notifies whenever the container is updated to hold an member"\
        " which does not case-equal (===) one of the arguments" do
      describe "[1, 2, 3].must_only_ever_contain(Numeric)" do
        subject { [1, 2, 3].must_only_ever_contain(Numeric) }
        
        notify_example %{subject << 3.14}
        notify_example %{subject << nil}, "must_only_ever_contain:"\
          " Array#<<(nil)\nnil.must_be(Numeric), but is NilClass in container"\
          " [1, 2, 3, nil]"
      end
    end
  end
  
  describe '#must_notify', " is a primitive used to define other must_be methods" do
    context "when called with a string, it notifies with a string message" do
      notify_example %{must_notify("message")}, "message"
    end
    
    context "when called with multiple arguments, it notifies with method"\
        " invocation details" do
      notify_example %{must_notify(:receiver, :method_name, [:arg, :arg, :arg],
        lambda {}, " additional message")}, ":receiver.method_name(:arg, :arg,"\
          " :arg) {} additional message"
    end
  end
  
  describe '#must_check', " interrupts normal notification" do
    context "when called with a block, it yields to the block" do
      example "#must_check returns a note if the block calls #must_notify" do
        note = must_check do
          must_notify("message")
        end
        note.message.should == "message"
        should_not notify
      end
      
      example "#must_check returns nil if the block does not call"\
          " #must_notify" do
        note = must_check do
          :would_not_notify
        end
        note.should be_nil
        should_not notify
      end
    end
    
    context "when called with a proc and a block, #must_check calls the"\
        " proc" do
      example "#must_check passes the note to the block and notifies with"\
          " the result of the block if the proc calls #must_notify" do
        must_check(lambda do
          must_notify("original message")
        end) do |note|
          note.message.should == "original message"
          "new message"
        end
        should notify("new message")
      end
      
      example "the block is not called if the proc does not call"\
          " #must_notify" do
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