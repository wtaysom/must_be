require 'spec_helper'

describe MustBe do
  include MustBeExampleHelper
  
### Enable ###

  describe ".disable" do
    before do
      MustBe.disable
    end
  
    after do
      MustBe.enable
    end
    
    it "should be disabled" do
      MustBe.enable?.should be_false
    end
    
    it "#must_be should not notify" do
      5799.must_be(:lolly).should == 5799
      should_not notify
    end
    
    it "#must_notify should return receiver (not a note)" do
      5799.must_notify("ignored message").should == 5799
      should_not notify
    end
    
    it "#must_check should not yield to its block" do
      yielded = false
      must_check { yielded = true }
      yielded.should be_false
    end
    
    it "#must should return receiver (not a proxy)" do
      :delegate.must.object_id.should == :delegate.object_id
    end
  end

  describe ".enable" do
    it "should start off enabled" do
      MustBe.enable?.should be_true
    end
    
    context "after disabling" do
      before do
       MustBe.disable
       MustBe.enable
      end
      
      it "should be enabled again" do
        MustBe.enable?.should be_true
      end
      
      it "#must_be should notify" do
        5799.must_be(:lolly).should == 5799
        should notify("5799.must_be(:lolly)")
      end

      it "#must_notify should return a note" do
        5799.must_notify("noted message").should be_a(Note)
        should notify("noted message")
      end

      it "#must_check should yield to its block" do
        yielded = false
        must_check { yielded = true }
        yielded.should be_true
      end

      it "#must should return a proxy" do
        :delegate.must.object_id.should_not == :delegate.object_id
      end
    end
  end
  
  describe "#must_just_return" do
    it "should return the sender" do
      :gnarly.must_just_return.should == :gnarly
      should_not notify
    end
  end

### Notifiers ###

  describe "RaiseNotifier" do    
    before do
      MustBe.notifier = RaiseNotifier
    end
    
    #!! spec other backtraces
    
    it "should raise Note" do      
      expect do
          must_notify("funny bunny")
      end.should(raise_error(Note, "funny bunny") do |note|
        note.backtrace[0].should_not match(/`must_notify'/)
      end)
    end
  end

### Note ###
  
  #!! check that Note#{inspect,to_s} does right thing
  #!! also check raising Note -- got stack level too deep at one point
  
  describe "#must_notify" do
    class <<self
      def it_should_notify(message)
        its(:message) { should == message }
        it("should notify") { should notify(message) }
      end
      
      def its_assertion_properties_should_be_nil
        its(:receiver) { should be_nil }
        its(:assertion) { should be_nil }
        its(:args) { should be_nil }
        its(:block) { should be_nil }
      end
    end
    
    block = lambda { nil }
        
    context "called with no arguments" do
      subject { must_notify }
      it_should_notify("MustBe::Note")
      its_assertion_properties_should_be_nil
    end
    
    context "called with single (message) argument" do
      subject { must_notify("message for note") }
      it_should_notify("message for note")
      its_assertion_properties_should_be_nil
    end
    
    context "called with existing note" do
      note = Note.new("existing note")
      
      subject { must_notify(note) }
      it_should_notify("existing note")
      it { should == note }
    end
    
    context "called with receiver and assertion" do
      subject { must_notify(4890, :must_be_silly) }
      it_should_notify("4890.must_be_silly")
      its(:receiver) { should == 4890 }
      its(:assertion) { should == :must_be_silly }
      its(:args) { should be_nil }
      its(:block) { should be_nil }
    end
    
    context "called with receiver, assertion, and an argument" do
      subject { must_notify(4890, :must_be_silly, [57]) }
      it_should_notify("4890.must_be_silly(57)")
      its(:receiver) { should == 4890 }
      its(:assertion) { should == :must_be_silly }
      its(:args) { should == [57] }
      its(:block) { should be_nil }
    end
    
    context "called with receiver, assertion, and arguments" do
      subject { must_notify(4890, :must_be_silly, [57, 71]) }
      it_should_notify("4890.must_be_silly(57, 71)")
      its(:receiver) { should == 4890 }
      its(:assertion) { should == :must_be_silly }
      its(:args) { should == [57, 71] }
      its(:block) { should be_nil }
    end
    
    context "called with receiver, assertion, and block" do
      block = lambda { nil }
      
      subject { must_notify(4890, :must_be_silly, nil, block) }
      it_should_notify("4890.must_be_silly {}")
      its(:receiver) { should == 4890 }
      its(:assertion) { should == :must_be_silly }
      its(:args) { should == nil }
      its(:block) { should == block }
    end
    
    context "called with receiver, assertion, arguments, and block" do
      subject { must_notify(4890, :must_be_silly, [57, 71], block) }
      it_should_notify("4890.must_be_silly(57, 71) {}")
      its(:receiver) { should == 4890 }
      its(:assertion) { should == :must_be_silly }
      its(:args) { should == [57, 71] }
      its(:block) { should == block }
    end
  end
  
  describe "#must_check" do
    context "when its block attempts to notify" do
      it "should return the note without notifying" do
        note = must_check do
          must_notify("ignored note")
          must_notify("returned note")
          "extra stuff"
        end
        should_not notify
        note.should be_a(Note)
        note.message.should == "returned note"
      end
    end
    
    context "when its block does not notify" do
      it "should return nil" do
        did_yield = false
        note = must_check { did_yield = true }
        did_yield.should be_true
        should_not notify
        note.should == nil
      end
    end
    
    it "should be able to be called multiple times" do
      note = must_check { must_notify("once") }
      should_not notify
      note.message.should == "once"
      
      note = must_check { must_notify("again") }
      should_not notify
      note.message.should == "again"
    end
    
    context "when nesting" do
      it "should be safe" do
        note = must_check do
          inner_note = must_check { must_notify("inner") }
          should_not notify
          inner_note.message.should == "inner"

          must_notify("outer")
        end
        should_not notify
        note.message.should == "outer"
      end
      
      it "should ignore inner checked notes" do
        note = must_check do
          must_notify("outer")
          must_check { must_notify("inner") }
        end
        should_not notify
        note.message.should == "outer"
      end
      
      it "should return nil if all inner notes are also checked" do
        note = must_check do
          must_check { must_notify("inner") }
        end
        should_not notify
        note.should == nil
      end
    end
    
    it "should be error safe" do
      expect do
        must_check do
          raise
        end
      end.should raise_error
      
      must_notify
      should notify
    end
    
    it "should be thread safe" do
      #! use Mutex and Conditional variables to test
      # <http://ruby-doc.org/docs/ProgrammingRuby/html/tut_threads.html>
      # should also check against Ruby 1.9 Fibers
      # -- I believe thread local variables are also fiber local
    end
  end

### Basic Assertions ###

  describe "#must_be" do
    context "when called with no arguments" do
      it "should notify if receiver is nil" do
        nil.must_be.should == nil
        should notify("nil.must_be")
      end
      
      it "should notify if receiver is false" do
        false.must_be.should == false
        should notify("false.must_be")
      end
    end
    
    context "given 51 as receiver" do
      context "when called with no arguments" do
        it "should not notify" do
          51.must_be.should == 51
          should_not notify
        end
      end
      
      context "when called with Numeric" do
        it "should not notify" do
          51.must_be(Numeric).should == 51
          should_not notify
        end
      end
      
      context "when called with Float" do
        it "should notify" do
          51.must_be(Float).should == 51
          should notify("51.must_be(Float)")
        end
      end
      
      context "when called with Comparable" do
        it "should not notify" do
          51.must_be(Comparable).should == 51
          should_not notify
        end
      end
      
      context "when called with Enumerable" do
        it "should notify" do
          51.must_be(Enumerable).should == 51
          should notify("51.must_be(Enumerable)")
        end
      end
      
      context "when called with Hash, Kernel, Object" do
        it "should not notify" do
          51.must_be(Hash, Kernel, Object).should == 51
          should_not notify
        end
      end
      
      context "when called with String, Time, Array" do
        it "should notify" do
          51.must_be(String, Time, Array).should == 51
          should notify("51.must_be(String, Time, Array)")
        end
      end
      
      #!! other `===' examples:
      # 71.must_be(lambda &:zero?, lambda &:odd?)
    end
  end
  
  describe "#must_not_be" do
    context "when called with no arguments" do
      it "should not notify if receiver is nil" do
        nil.must_not_be.should == nil
        should_not notify
      end
      
      it "should not notify if receiver is false" do
        false.must_not_be.should == false
        should_not notify
      end
    end
    
    context "given 51 as receiver" do      
      context "when called with no arguments" do
        it "should notify" do
          51.must_not_be.should == 51
          should notify("51.must_not_be")
        end
      end
      
      context "when called with Numeric" do
        it "should notify" do
          51.must_not_be(Numeric)
          should notify("51.must_not_be(Numeric)")
        end
      end
      
      context "when called with Float" do
        it "should not notify" do
          51.must_not_be(Float).should == 51
          should_not notify
        end
      end
      
      context "when called with Comparable" do
        it "should notify" do
          51.must_not_be(Comparable)
          should notify("51.must_not_be(Comparable)")
        end
      end
      
      context "when called with Enumerable" do
        it "should not notify" do
          51.must_not_be(Enumerable).should == 51
          should_not notify
        end
      end
      
      context "when called with Hash, Kernel, Object" do
        it "should notify" do
          51.must_not_be(Hash, Kernel, Object).should == 51
          should notify("51.must_not_be(Hash, Kernel, Object)")
        end
      end
      
      context "when called with String, Time, Array" do
        it "should not notify" do
          51.must_not_be(String, Time, Array).should == 51
          should_not notify
        end
      end
    end
  end
  
  shared_examples_for "*_be_in in case of bad arguments" do
    context "when called with :does_not_respond_to_include?" do
      it "should raise NoMethodError" do
        expect do
          "hi".send(the_method_name, :does_not_respond_to_include?)
        end.should raise_error NoMethodError
      end
    end
  end
  
  describe "#must_be_in" do
    let(:the_method_name) { :must_be_in }
    it_should_behave_like "*_be_in in case of bad arguments"
    
    context "given \"hi\" as receiver" do
      context "when called with empty array" do
        it "should notify" do
          "hi".must_be_in([]).should == "hi"
          should notify(%{"hi".must_be_in([])})
        end
      end
      
      context "when called with an array which does not include it" do
        it "should notify" do
          "hi".must_be_in(["happy", "helper", "hiccup"]).should == "hi"
          should notify(
            %{"hi".must_be_in(["happy", "helper", "hiccup"])})
        end
      end
      
      context "when called with a range which includes it" do
        it "should not notify" do
          "hi".must_be_in("ah".."oh").should == "hi"
          should_not notify
        end
      end
      
      context "when called with a string which includes it" do
        it "should not notify" do
          "hi".must_be_in("wishing").should == "hi"
          should_not notify
        end
      end
    end
  end
  
  describe "#must_not_be_in" do
    let(:the_method_name) { :must_not_be_in }
    it_should_behave_like "*_be_in in case of bad arguments"
    
    context "given \"hi\" as receiver" do
      context "when called with empty array" do
        it "should not notify" do
          "hi".must_not_be_in([]).should == "hi"
          should_not notify
        end
      end
      
      context "when called with an array which does not include it" do
        it "should not notify" do
          "hi".must_not_be_in(["happy", "helper", "hiccup"]).should == "hi"
          should_not notify
        end
      end
      
      context "when called with a range which includes it" do
        it "should notify" do
          "hi".must_not_be_in("ah".."oh").should == "hi"
          should notify(%{"hi".must_not_be_in("ah".."oh")})
        end
      end
      
      context "when called with a string which includes it" do
        it "should notify" do
          "hi".must_not_be_in("wishing").should == "hi"
          should notify(%{"hi".must_not_be_in("wishing")})
        end
      end
    end
  end
  
  it_should_have_must_be_value_assertion :must_be_nil, nil
  it_should_have_must_not_be_value_assertion :must_not_be_nil, nil
  it_should_have_must_be_value_assertion :must_be_true, true
  it_should_have_must_be_value_assertion :must_be_false, false
  
  describe "#must_be_boolean" do
    it "should not notify if receiver is true" do
      true.must_be_boolean.should == true
      should_not notify
    end
    
    it "should not notify if receiver is false" do
      false.must_be_boolean.should == false
      should_not notify
    end
    
    it "should notify if receiver is nil" do
      nil.must_be_boolean.should == nil
      should notify("nil.must_be_boolean")
    end
    
    it "should notify if receiver is zero" do
      0.must_be_boolean.should == 0
      should notify("0.must_be_boolean")
    end
  end
  
  shared_examples_for "*_be_close in case of bad arguments" do  
    it "should raise ArgumentError if delta cannot be compared" do      
      expect do
        200.0.send(the_method_name, 2.0, :a_little)
      end.should raise_error ArgumentError
    end
    
    it "should raise TypeError if expected cannot be subtracted from "\
        "receiver" do
      expect do
        200.0.send(the_method_name, :some)
      end.should raise_error TypeError
    end

    it "should raise NoMethodError if receiver does not respond to `-'" do
      expect do
        :lots.send(the_method_name, 2.0)
      end.should raise_error NoMethodError
    end

    it "should rasie NoMethodError if `receiver - expected' does not "\
        "respond to `abs'" do
      expect do
        Time.new.send(the_method_name, 2.0, :five)
      end.should raise_error NoMethodError
    end
  end
  
  describe "#must_be_close" do
    let(:the_method_name) { :must_be_close }
    it_should_behave_like "*_be_close in case of bad arguments"
    
    it "should not notify if receiver is the same" do
      2.0.must_be_close(2.0).should == 2.0
      should_not notify
    end
    
    it "should not notify if receiver is a bit greater" do
      2.01.must_be_close(2.0).should == 2.01
      should_not notify
    end
    
    it "should not notify if receiver is a bit less" do
      1.91.must_be_close(2.0).should == 1.91
      should_not notify
    end
    
    it "should notify if receiver is much greater" do
      200.0.must_be_close(2.0, 20.0).should == 200.0
      should notify("200.0.must_be_close(2.0, 20.0)")
    end
    
    it "should notify if receiver is much less" do
      -200.0.must_be_close(2.0, 20.0).should == -200.0
      should notify("-200.0.must_be_close(2.0, 20.0)")
    end
  end
  
  describe "#must_not_be_close" do
    let(:the_method_name) { :must_not_be_close }
    it_should_behave_like "*_be_close in case of bad arguments"
    
    it "should notify if receiver is the same" do
      2.0.must_not_be_close(2.0).should == 2.0
      should notify("2.0.must_not_be_close(2.0, 0.1)")
    end
    
    it "should notify if receiver is a bit greater" do
      2.01.must_not_be_close(2.0).should == 2.01
      should notify("2.01.must_not_be_close(2.0, 0.1)")
    end
    
    it "should notify if receiver is a bit less" do
      1.91.must_not_be_close(2.0).should == 1.91
      should notify("1.91.must_not_be_close(2.0, 0.1)")
    end
    
    it "should not notify if receiver is much greater" do
      200.0.must_not_be_close(2.0, 20.0).should == 200.0
      should_not notify
    end
    
    it "should not notify if receiver is much less" do
      -200.0.must_not_be_close(2.0, 20.0).should == -200.0
      should_not notify
    end
  end
  
### must and must_not ###

  describe Proxy do
    subject { Proxy.new(:moxie) }
    
    #!! spec its initialize method
    
    context "when it forwards" do
      #!! just an example or two
    end
    
    context "when it does not forward" do
      #!! a few methods should not forward, which ones?
      #     __id__, object_id, __send__ and all the private_instance_methods
    end
  end
  
  describe "#must" do
    class <<self
      def it_should_notify(message, &implementation)
        it "`#{message}' should notify" do
          instance_eval &implementation
          should notify(message)
        end
      end
    
      def it_should_not_notify(message, &implementation)
        it "`#{message}' should not notify" do
          instance_eval &implementation
          should_not notify
        end
      end
    end
    
    context "when called with a block" do
      it "should return the receiver" do
        0xdad.must{}.should == 0xdad
      end
      
      it "should notify if block returns false" do
        :helm.must{|receiver, message| receiver == :harm }.should == :helm
        should notify(":helm.must {}")
      end
      
      it "shoud notify with message if provided" do
        :ice.must("ice must be icy") do |receiver, message|
          receiver == :icy
        end.should == :ice
        should notify("ice must be icy")
      end
      
      it "should not notify if block returns true" do
        :jinn.must{|receiver, message| receiver == :jinn }.should == :jinn
        should_not notify
      end
      
      it "should allow nested #must_notify" do
        :keys.must("electrify kites") do |receiver, message|
          must_notify("#{receiver} must #{message}")
        end.should == :keys
        should notify("keys must electrify kites")
      end
    end
    
    context "when used to proxy" do      
      subject { 0xabaca_facade.must }
      
      it_should_notify("#{0xabaca_facade}.must.==(#{0xdefaced})") do
        subject == 0xdefaced
      end
        
      it_should_not_notify("#{0xabaca_facade}.must.>(#{0xfaded})") do
        subject > 0xfaded
      end
      
      it_should_not_notify("#{0xabaca_facade}.must.even?") do
        subject.even?
      end
      
      it_should_notify("#{0xabaca_facade}.must.between?(-4, 4)") do
        subject.between?(-4, 4)
      end
      
      it_should_notify("#{0xabaca_facade}.must.respond_to?(:finite?)") do
        subject.respond_to? :finite?
      end
      
      it_should_not_notify("#{0xabaca_facade}.must.instance_of(Fixnum)") do
        subject.instance_of? Fixnum
      end
      
      it_should_notify("#{0xabaca_facade}.must.instance_of?(Integer)") do
        subject.instance_of? Integer
      end    
    end
  end
  
  describe "#must_not" do
    #!! dual of #must
  end
  
### Containers ###
  
  describe "#must_only_contain" do
    #!! be serious about your examples
    describe Array do
      subject { [11, :sin, 'cos'] }
      
      it "should not notify when each member matches one of the cases" do
        subject.must_only_contain(Symbol, Numeric, String).should == subject
        should_not notify
      end
    
      it "should notify when any member matches none of the cases" do
        subject.must_only_contain(Symbol, Numeric).should == subject
        should notify #!! check format of the message
      end
    
      context "when there are no cases" do
        it "should notify if any member is conditionally false" do
          [false, nil].must_only_contain
          should notify #!! check format of the message
        end
      
        it "should not notify if each member is conditionally true" do
          [0, [], ""].must_only_contain
          should_not notify
        end
      end
    end
    
    describe Hash do
      subject { {:key => :value, :another => 'thing', 12 => 43} }
      
      it "should not notify when each pair matches one of the cases" do
        subject.must_only_contain({Symbol => Symbol}, {Symbol => String,
          Numeric => Numeric}).should == subject
        should_not notify
      end
      
      it "should notify when any pair match none of the cases" do
        subject.must_only_contain(Symbol => Symbol, Symbol => String,
          Numeric => Numeric).should == subject
        should notify #!! message?
      end
    end
  end
  
  describe "#must_only_ever_contain" do
    #!! be more serious about your examples -- what should raise errors?
    #!! should check that the initial contents are okay
    #!! update must_only_ever_contain_cases should check all contents again
    describe Hash do
      #!! note that the Hash cases can only specify one value per key
      # (just like normal hashes) e.g. {Symbol => Integer, Symbol => Float} is
      # the same as {Symbol => Float} instead use two cases:
      # {Symbol => Integer}, {Symbol => Float}
      #!! spec Hash receiver when cases is empty
      subject { {}.must_only_ever_contain Symbol => Integer,
        Integer => Symbol }
    
      its(:must_only_ever_contain_cases) do
        should == [{Symbol => Integer, Integer => Symbol}]
      end
    
      it "should not notify when cases match" do
        subject[:good] = 34
        subject[34] = :also_good
        should_not notify
        subject[:good].should == 34
        subject[34].should == :also_good
      end
    
      context "when cases do not match" do
        before do
          subject[:bad] = 4.5
        end
      
        #! rSpec has some way to automatically generate descriptions for
        # methods like this
        it "should notify" do
          should notify #!! specify the message
        end
      
        it "should insert the value (unless MustBe.notifier raises error)" do
          subject[:bad].should == 4.5
        end
      end
    end
  end
end

### Proc Case Equality Patch ###

describe "case equality patch" do
  describe "Proc#===" do
    it "should work the same as Proc#call" do
      is_less_than_three = lambda {|x| x < 3 }
      is_less_than_three.should === 2
      is_less_than_three.should_not === 7
      
      is_even = lambda &:even?
      is_even.should === 2
      is_even.should_not === 7
    end
    
    if RUBY_VERSION < "1.9"
      it "should alias Proc#call" do
        Proc.instance_method(:===).should == Proc.instance_method(:call)
      end
    end
  end
end

###! to-do ###
=begin

== Main things ==

#must_only_ever_contain
  Array unimplemented
  Hash only checks when you use `[]='

Messages
  some errors aren't really checked
  the messages for some assertions could be improved

Notifiers
  more built-in ones
  use ENV to configure

== Hodgepodge ==

-- configuration:
  ENV['MUST_BE__NOTIFIER'] = 'raise' (default), 'disable', 'notify', 'test', 'spec', 'debug'
  -- check that the default is properly set to MustBe::RaiseNotifier

#must_only_ever_contain
  (String => String, String => Array) -- for hashes
  (Symbol, Array) -- for arrays
  -- be able to register other collections, complain if unregistered
  -- complain if the collection already has singleton methods

spec MustBe::Proxy (just the initializer)
spec #must_be and #must_not_be against `==='

#must_not_contain
#must_never_contain
  -- duels

spec Note
  mostly covered by #must_notify
  show the difference between complete_backtrace and backtrace

spec ENV["MUST_BE__SHOULD_NOT_AUTOMATICALLY_BE_INCLUDED_IN_OBJECT"]

spec usage examples at the top

seperate into multiple files, refactor, remove excess duplication
  see <http://pure-rspec-rubynation.heroku.com/> shared behaviors (30-32)
  let for providing differences to use in shared behaviors
  put more things in spec_helper?
  learn rSpec better before diving into this stuff
    read tRSb chapter 17 specifically Custom Matchers and Macros
    use a double (perhaps as_nul_object) or some other object as the MustBe.notifier (with should_receive method) -- then we don't need that @note instance variable

icing
  rdoc (focus on examples), check out rcov <http://eigenclass.org/hiki.rb?rcov>
=end