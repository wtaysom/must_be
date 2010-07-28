require 'spec_helper'

describe MustBe do
  include MustBeExampleHelper
  
  QUOTATION_MARKS = 2
  
  describe ".short_inspect" do
    it "should not shorten strings of length"\
        " MustBe::SHORT_INSPECT_CUTOFF_LENGTH" do
      s = "x" * (MustBe::SHORT_INSPECT_CUTOFF_LENGTH - QUOTATION_MARKS)
      s.inspect.length.should == MustBe::SHORT_INSPECT_CUTOFF_LENGTH
      si = MustBe.short_inspect(s)
      si.should == s.inspect
    end
    
    it "should shorten strings longer than"\
        " MustBe::SHORT_INSPECT_CUTOFF_LENGTH characters" do
      s = "x" * MustBe::SHORT_INSPECT_CUTOFF_LENGTH
      s.inspect.length.should == MustBe::SHORT_INSPECT_CUTOFF_LENGTH +
        QUOTATION_MARKS
      si = MustBe.short_inspect(s)
      si.length.should == MustBe::SHORT_INSPECT_CUTOFF_LENGTH
    end
    
    it "should break at word boundries if possible" do
      side_length = MustBe::SHORT_INSPECT_CUTOFF_LENGTH / 2
      padding = "x" * (side_length - 7)
      s = "#{padding} helloXXXXXworld #{padding}"
      is = MustBe.short_inspect(s)
      is.should match("xx ... xx")
    end
    
    it "should be used by MustBe" do
      s = "x" * MustBe::SHORT_INSPECT_CUTOFF_LENGTH
      s.must_be(Symbol)
      should notify(/"x*\.\.\.x*"\.must_be\(Symbol\), but is String/)
    end
  end
  
### Enable ###

  describe ".disable" do
    before do
      MustBe.disable
    end
  
    after do
      MustBe.enable
    end
    
    it "should be disabled" do
      MustBe.enabled?.should be_false
    end
    
    example "#must_be should not notify" do
      5799.must_be(:lolly).should == 5799
      should_not notify
    end
    
    example "#must_notify should return receiver (not a note)" do
      5799.must_notify("ignored message").should == 5799
      should_not notify
    end
    
    example "#must_check should not yield to its block" do
      yielded = false
      must_check { yielded = true }
      yielded.should be_false
    end
    
    example "#must should return receiver (not a proxy)" do
      :delegate.must.object_id.should == :delegate.object_id
    end
  end

  describe ".enable" do
    it "should start off enabled" do
      MustBe.enabled?.should be_true
    end
    
    context "after disabling" do
      before do
       MustBe.disable
       MustBe.enable
      end
      
      it "should be enabled again" do
        MustBe.enabled?.should be_true
      end
      
      example "#must_be should notify" do
        5799.must_be(:lolly).should == 5799
        should notify("5799.must_be(:lolly), but is Fixnum")
      end

      example "#must_notify should return a note" do
        5799.must_notify("noted message").should be_a(Note)
        should notify("noted message")
      end

      example "#must_check should yield to its block" do
        yielded = false
        must_check { yielded = true }
        yielded.should be_true
      end

      example "#must should return a proxy" do
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

  describe "default notifier" do
    it "should be RaiseNotifier" do
      $default_must_be_notifier.should == MustBe::RaiseNotifier
    end
  end
  
  describe ".set_notifier_from_env" do
    before do
      $notifier = MustBe.notifier
    end
    
    after do
      MustBe.notifier = $notifier
    end
    
    it "should use 'log' to set the LogNotifier" do
      MustBe.set_notifier_from_env('log')
      MustBe.notifier.should == MustBe::LogNotifier
    end
    
    it "should use ENV['MUST_BE__NOTIFIER'] when no argument provided" do
      ENV['MUST_BE__NOTIFIER'] = 'debug'
      MustBe.set_notifier_from_env
      MustBe.notifier.should == MustBe::DebugNotifier
    end
    
    it "should raise NoMethodError when argument does not respond to :to_sym" do
      expect do
        MustBe.set_notifier_from_env(nil)
      end.should raise_error(NoMethodError)
    end
    
    it "should raise ArgumentError when unknown notifier name provided" do
      expect do
        MustBe.set_notifier_from_env(:unknown)
      end.should raise_error(ArgumentError)
    end
        
    it "should treat 'disable' as a special case" do
      MustBe.set_notifier_from_env('disable')
      MustBe.should_not be_enabled
      MustBe.notifier.should == $notifier
      MustBe.enable
      MustBe.should be_enabled
    end
  end
  
  describe ".def_notifier" do
    context "when called with a key" do
      before :all do
        MustBe.def_notifier(:Spec__ExampleNotifier, :spec__example) {}
      end
      
      it "should set a constant" do
        MustBe::Spec__ExampleNotifier.should be_a(Proc)
      end
      
      it "should add the key to NOTIFIERS" do
        MustBe::NOTIFIERS[:spec__example].should == :Spec__ExampleNotifier
      end
      
      it "should extend .set_notifier_from_env" do
        MustBe.set_notifier_from_env(:spec__example)
        MustBe.notifier.should == MustBe::Spec__ExampleNotifier
      end
    end
    
    context "when called with no key" do
      before :all do
        @original_notifiers = MustBe::NOTIFIERS.clone
        
        MustBe.def_notifier(:Spec__SecondExampleNotifier) {}
      end
      
      it "should set a constant" do
        MustBe::Spec__SecondExampleNotifier.should be_a(Proc)
      end
      
      it "should leave NOTIFIERS unchanged" do
        MustBe::NOTIFIERS.should == @original_notifiers
      end
    end
  end

  describe "RaiseNotifier" do    
    before do
      MustBe.notifier = RaiseNotifier
    end
        
    it "should raise Note" do      
      expect do
          must_notify("funny bunny")
      end.should(raise_error(Note, "funny bunny") do |note|
        note.backtrace[0].should_not match(/`must_notify'/)
      end)
    end
  end

### Note ###
  
  describe "Note" do
    # #must_notify provides examples covering #initialize and #to_s.
    
    describe "difference between #backtrace and #complete_backtrace" do
      example "#backtrace should drop lines containing %r{lib/must_be.*\\.rb:}"\
          " from #complete_backtrace" do
        backtrace = [
          "first line kept",
          "other lib/must_be.rb: kept as well"]
        
        complete_backtrace = [
          "lib/must_be.rb: at start",
          "in middle lib/must_be_elsewhere.rb: is okay",
          "at end too lib/must_be_yet_again.rb:",
          *backtrace]
        
        note = Note.new("sample")
        note.set_backtrace(complete_backtrace)
        
        note.complete_backtrace.should == complete_backtrace
        note.backtrace.should == backtrace
      end
    end
  end
  
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
        its(:additional_message) { should be_nil }
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
    
    context "with #additional_message" do
      subject do
        must_notify(5, :must_be, [String], nil, ", but is Fixnum")
      end
      
      it_should_notify("5.must_be(String), but is Fixnum")
      its(:receiver) { should == 5 }
      its(:assertion) { should == :must_be }
      its(:args) { should == [String] }
      its(:block) { should be_nil }
      its(:additional_message) { should == ", but is Fixnum"}
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
    
    context "when called with a proc" do
      it "should not call its block if the proc does not notify" do
        did_call_block = false
        must_check(lambda {}) do
          did_call_block = true
        end
        did_call_block.should be_false
      end
      
      it "should call its block and notify if the proc notifies" do
        did_call_block = false
        must_check(lambda { must_notify("check") }) do |note|
          did_call_block = true
          note.message.should == "check"
          Note.new("mate")
        end
        did_call_block.should be_true
        should notify("mate")
      end
      
      it "should use the result of the proc to generate a new note" do
        did_call_block = false
        must_check(lambda { must_notify("check") }) do |note|
          did_call_block = true
          note.message.should == "check"
          "mate"
        end
        did_call_block.should be_true
        should notify("mate")
      end
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
    
    describe "safety" do
      it "should be able to be called multiple times" do
        note = must_check { must_notify("once") }
        should_not notify
        note.message.should == "once"
      
        note = must_check { must_notify("again") }
        should_not notify
        note.message.should == "again"
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
        mutex = Mutex.new
        cv = ConditionVariable.new
      
        cv_yield = lambda do
          cv.signal
          cv.wait(mutex)
        end
      
        thread = nil
        thread_note = nil
        note = nil
            
        thread_block = lambda do
          mutex.synchronize do
            thread_note = must_check do
              must_notify("thread")
              cv_yield[]
            end
          end
        end
      
        mutex.synchronize do
          note = must_check do
            must_notify("main")
            thread = Thread.new &thread_block
            cv_yield[]
          end
          cv.signal
        end
        thread.join
      
        note.message.should == "main"
        thread_note.message.should == "thread"    
      end
    
      if RUBY_VERSION > "1.9"
        fiber_note = nil
      
        it "should be fiber safe" do
          fiber_note = nil
        
          fiber = Fiber.new do
            fiber_note = must_check do
              must_notify("fiber")
              Fiber.yield
            end
          end
        
          note = must_check do
            must_notify("main")
            fiber.resume
          end
          fiber.resume
        
          note.message.should == "main"
          fiber_note.message.should == "fiber"
        end
      end
    end
  end

### Basic Assertions ###

  describe "#must_be" do
    context "when called with no arguments" do
      it "should notify if receiver is nil" do
        nil.must_be.should == nil
        should notify("nil.must_be, but is NilClass")
      end
      
      it "should notify if receiver is false" do
        false.must_be.should == false
        should notify("false.must_be, but is FalseClass")
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
          should notify("51.must_be(Float), but is Fixnum")
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
          should notify("51.must_be(Enumerable), but is Fixnum")
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
          should notify("51.must_be(String, Time, Array), but is Fixnum")
        end
      end
      
      context "when called with [1, 51]" do
        it "should notify" do
          51.must_be([1, 51]).should == 51
          should notify("51.must_be([1, 51]), but is Fixnum")
        end
      end
      
      context "when called with blocks" do
        let(:zerop) { lambda &:zero? }
        let(:oddp) { lambda &:odd? }
        
        context "when called with zerop" do
          it "should notify" do
            51.must_be(zerop).should == 51
            should notify
          end
        end
        
        context "when called with oddp" do
          it "should not notify" do
            51.must_be(oddp).should == 51
            should_not notify
          end
        end
        
        context "when called with zerop, oddp" do
          it "should not notify" do
            51.must_be(zerop, oddp).should == 51
            should_not notify
          end
        end
      end
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
          should notify("51.must_not_be, but is Fixnum")
        end
      end
      
      context "when called with Numeric" do
        it "should notify" do
          51.must_not_be(Numeric)
          should notify("51.must_not_be(Numeric), but is Fixnum")
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
          should notify("51.must_not_be(Comparable), but is Fixnum")
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
          should notify("51.must_not_be(Hash, Kernel, Object), but is Fixnum")
        end
      end
      
      context "when called with String, Time, Array" do
        it "should not notify" do
          51.must_not_be(String, Time, Array).should == 51
          should_not notify
        end
      end
      
      context "when called with [1, 51]" do
        it "should notify" do
          51.must_not_be([1, 51]).should == 51
          should_not notify
        end
      end
      
      context "when called with blocks" do
        let(:zerop) { lambda &:zero? }
        let(:oddp) { lambda &:odd? }
        
        context "when called with zerop" do
          it "should not notify" do
            51.must_not_be(zerop).should == 51
            should_not notify
          end
        end
        
        context "when called with oddp" do
          it "should notify" do
            51.must_not_be(oddp).should == 51
            should notify
          end
        end
        
        context "when called with zerop, oddp" do
          it "should notify" do
            51.must_not_be(zerop, oddp).should == 51
            should notify
          end
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
    
    it "should raise TypeError if expected cannot be subtracted from"\
        " receiver" do
      expect do
        200.0.send(the_method_name, :some)
      end.should raise_error TypeError
    end

    it "should raise NoMethodError if receiver does not respond to `-'" do
      expect do
        :lots.send(the_method_name, 2.0)
      end.should raise_error NoMethodError
    end

    it "should rasie NoMethodError if `receiver - expected' does not"\
        " respond to `abs'" do
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
    
    context "when initialized with invalid method" do
      it "should raise ArgumentError" do
        expect do
          Proxy.new(:moxie, :must_could)
        end.should raise_error(ArgumentError,
          "assertion (:must_could) must be :must or :must_not")
      end
    end
    
    context "when it should not forward" do
      example "#__id__" do
        subject.__id__.should_not == :moxie.__id__
      end
      
      example "#object_id" do
        subject.object_id.should_not == :moxie.object_id
      end      
    end
  end
  
  module ItShouldNotifyExpectations
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
  
  describe "#must" do
    extend ItShouldNotifyExpectations
    
    context "when called with a block" do
      it "should return the receiver" do
        0xdad.must{}.should == 0xdad
      end
      
      it "should notify if block returns false" do
        :helm.must{|receiver| receiver == :harm }.should == :helm
        should notify(":helm.must {}")
      end
      
      it "should notify with message if provided" do
        :ice.must("ice must be icy") do |receiver|
          receiver == :icy
        end.should == :ice
        should notify("ice must be icy")
      end
      
      it "should not notify if block returns true" do
        :jinn.must{|receiver| receiver == :jinn }.should == :jinn
        should_not notify
      end
      
      it "should allow nested #must_notify" do
        :keys.must("electrify kites") do |receiver, message|
          must_notify("#{receiver} must #{message}")
          true
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
      
      it_should_not_notify("#{0xabaca_facade}.must.instance_of?(Fixnum)") do
        subject.instance_of? Fixnum
      end
      
      it_should_notify("#{0xabaca_facade}.must.instance_of?(Integer)") do
        subject.instance_of? Integer
      end    
    end
  end
  
  describe "#must_not" do    
    extend ItShouldNotifyExpectations
        
    context "when called with a block" do
      it "should return the receiver" do
        0xdad.must_not{}.should == 0xdad
      end
      
      it "should notify if block returns true" do
        :helm.must_not{|receiver| receiver == :helm }.should == :helm        
        should notify(":helm.must_not {}")
      end
      
      it "should notify with message if provided" do
        :ice.must_not("ice must not be ice") do |receiver|
          receiver == :ice
        end.should == :ice
        should notify("ice must not be ice")
      end
      
      it "should not notify if block returns false" do
        :jinn.must_not{|receiver| receiver == :gem }.should == :jinn
        should_not notify
      end
      
      it "should allow nested #must_notify" do
        :keys.must_not("electrify kites") do |receiver, message|
          must_notify("#{receiver} must not #{message}")
          false
        end.should == :keys
        should notify("keys must not electrify kites")
      end
    end
    
    context "when used to proxy" do      
      subject { 0xabaca_facade.must_not }
      
      it_should_not_notify("#{0xabaca_facade}.must_not.==(#{0xdefaced})") do
        subject == 0xdefaced
      end
        
      it_should_notify("#{0xabaca_facade}.must_not.>(#{0xfaded})") do
        subject > 0xfaded
      end
      
      it_should_notify("#{0xabaca_facade}.must_not.even?") do
        subject.even?
      end
      
      it_should_not_notify("#{0xabaca_facade}.must_not.between?(-4, 4)") do
        subject.between?(-4, 4)
      end
      
      it_should_not_notify(
          "#{0xabaca_facade}.must_not.respond_to?(:finite?)") do
        subject.respond_to? :finite?
      end
      
      it_should_notify("#{0xabaca_facade}.must_not.instance_of?(Fixnum)") do
        subject.instance_of? Fixnum
      end
      
      it_should_not_notify(
          "#{0xabaca_facade}.must_not.instance_of?(Integer)") do
        subject.instance_of? Integer
      end    
    end
  end
  
### Containers ###

  describe ContainerNote do
    describe "#backtrace" do
      context "when container must_only_ever_contain" do
        subject do
          note = ContainerNote.new(Note.new("nothing"),
            [].must_only_ever_contain)
          note.set_backtrace([])
          note
        end
    
        its(:backtrace) { should include("=== caused by container ===")}
      end
    
      context "when container has not been set to must_only_ever_contain" do
        subject do
          note = ContainerNote.new(Note.new("nothing"), [])
          note.set_backtrace([])
          note
        end
    
        its(:backtrace) { should_not include("=== caused by container ===")}
      end
    end
  end
  
  describe "#must_only_contain" do
    describe Array do
      subject { [11, :sin, 'cos'] }
      
      it "should not notify if every member matches one of the cases" do
        subject.must_only_contain(Symbol, Numeric, String).should == subject
        should_not notify
      end
    
      it "should notify if any member matches none of the cases" do
        subject.must_only_contain(Symbol, Numeric).should == subject
        should notify("must_only_contain: \"cos\".must_be(Symbol, Numeric),"\
          " but is String in container [11, :sin, \"cos\"]")
      end
    
      context "when there are no cases" do
        it "should notify if any member is conditionally false" do
          [false, nil].must_only_contain
          should notify
        end
      
        it "should not notify if every member is conditionally true" do
          [0, [], ""].must_only_contain
          should_not notify
        end
      end
    end
    
    describe Hash do
      subject { {:key => :value, :another => 'thing', 12 => 43} }
      
      describe "note message" do
        it "should include \"does not match\"" do
          subject = {:key => :value}
          subject.must_only_contain(Symbol => [String, Numeric])
          should notify("must_only_contain: pair {:key=>:value} does not match"\
            " [{Symbol=>[String, Numeric]}] in container {:key=>:value}")
        end
      end
      
      context "when called with no arguments" do
        it "should not notifiy if every key and value is non-nil" do
          subject = {:key => :value}
          subject.must_only_contain
          should_not notify
        end
        
        it "should notify if any pair contains a nil key" do
          subject = {nil => :value}
          subject.must_only_contain
          should notify
        end
        
        it "should notify if any pair contains a nil value" do
          subject = {:key => nil}
          subject.must_only_contain
          should notify
        end
      end
      
      context "when called with a single hash" do
        it "should not notify if every pair matches one of the cases" do
          subject.must_only_contain(Symbol => [Symbol, String],
            Numeric => Numeric).should == subject
          should_not notify
        end
        
        it "should notify if any pair matches none of the cases" do
          subject.must_only_contain(Symbol => Symbol, Symbol => String,
            String => Numeric).should == subject
          should notify
        end
      end
      
      context "when called with multiple hashes" do
        it "should not notify if every pair matches one of the cases" do
          subject.must_only_contain({Symbol => Symbol}, {Symbol => String},
            {Numeric => Numeric}).should == subject
          should_not notify
        end
        
        it "should notify if any pair matches none of the cases" do
          subject.must_only_contain({Symbol => Symbol}, {Symbol => String},
            {String => Numeric}).should == subject
          should notify
        end
      end
      
      context "when called with array keys and values" do
        it "should not notify if every pair matches one of the cases" do
          subject.must_only_contain([Symbol, Numeric] => [Symbol, String, 
            Numeric]).should == subject
          should_not notify
        end
        
        it "should notify if any pair does not match any of the cases" do
          subject.must_only_contain([Symbol, Numeric] => [Symbol, 
            Numeric]).should == subject
          should notify
        end
      end
    end
  end
  
  describe "#must_not_contain" do
    describe Array do
      subject { [11, :sin, 'cos'] }
      
      it "should not notify if no member matches any of the cases" do
        subject.must_not_contain(Float, Range).should == subject
        should_not notify
      end
    
      it "should notify if any member matches one of the cases" do        
        subject.must_not_contain(Range, Numeric).should == subject
        should notify("must_not_contain: 11.must_not_be(Range, Numeric),"\
          " but is Fixnum in container [11, :sin, \"cos\"]")
      end
    
      context "when there are no cases" do
        it "should not notify if every member is conditionally false" do
          [false, nil].must_not_contain
          should_not notify
        end
      
        it "should notify if any member is conditionally true" do
          [0, [], ""].must_not_contain
          should notify
        end
      end
    end
    
    describe Hash do
      subject { {:key => :value, :another => 'thing', 12 => 43} }
      
      context "when called with no arguments" do
        it "should not notifiy if every key and value is conditionally false" do
          subject = {nil => false, false => nil}
          subject.must_not_contain
          should_not notify
        end
        
        it "should notify if any key or value is conitionally true" do
          subject = {nil => :value}
          subject.must_not_contain
          should notify
        end
      end
      
      describe "note message" do
        it "should include \"does match\"" do
          subject = {:key => :value}
          subject.must_not_contain(Symbol => [String, Symbol])
          should notify("must_not_contain: pair {:key=>:value} matches"\
            " [{Symbol=>[String, Symbol]}] in container {:key=>:value}")
        end
      end
      
      context "when called with a single hash" do
        it "should notify if any pair matches one of the cases" do
          subject.must_not_contain(Symbol => [Symbol, String],
            Numeric => Numeric).should == subject
          should notify
        end
        
        it "should_not notify if no pair matches any of the cases" do
          subject.must_not_contain(Symbol => Numeric, String => String,
            Range => Numeric).should == subject
          should_not notify
        end
      end
      
      context "when called with multiple hashes" do
        it "should not notify if no pair matches any of the cases" do
          subject.must_not_contain({Symbol => Numeric}, {String => String},
            {String => Numeric}).should == subject
          should_not notify
        end
        
        it "should notify if any pair matches any of the cases" do
          subject.must_not_contain({Symbol => Symbol}, {Symbol => String},
            {String => Numeric}).should == subject
          should notify
        end
      end
      
      context "when called with array keys and values" do
        it "should not notify if no pair matches any of the cases" do
          subject.must_not_contain([Range, Numeric] => [Symbol, String, 
            Float]).should == subject
          should_not notify
        end
        
        it "should notify if any pair matches one of the cases" do
          subject.must_not_contain([Symbol, Numeric] => [Symbol, 
            Numeric]).should == subject
          should notify
        end
      end
    end
  end
  
  shared_examples_for "custom MustOnlyEverContain" do
    class Box
      include Enumerable
      
      attr_accessor :contents
      
      def initialize(contents = nil)
        self.contents = contents
      end
      
      def each_called?
        @each_called
      end
      
      def each
        @each_called = true
        yield(contents) unless contents.nil?
      end
      
      def empty!
        self.contents = nil
      end
    end
    
    subject { Box.new(:contents) }
    
    def self.register_before_and_unregister_after
      before do
        MustOnlyEverContain.register(Box) do
          def self.must_only_contain_check(object, cases, negate = false)
            if negate
              object.contents.must_not_be(*cases)
            else
              object.contents.must_be(*cases)
            end              
          end
          
          def contents=(contents)
            must_check_item(contents)
            super
          end
          
          must_check_contents_after :empty!
        end
      end
      
      after do
        MustOnlyEverContain.unregister(Box)
      end
    end
  end
  
  describe "#must_only_ever_contain" do
    describe Array do
      subject { [1, 2, 3, 4] }
      
      before do
        subject.must_only_ever_contain
      end
      
      it "should notify if initially contains a non-matching item" do
        array = [:oops]
        array.must_only_ever_contain(String)
        should notify("must_only_ever_contain: :oops.must_be(String), but is"\
          " Symbol in container [:oops]")
      end
      
      describe "#<<" do
        it "should not notify if obj is non-nil" do
          subject << 5
          should_not notify
        end
        
        it "should notify if obj is nil" do
          subject << nil
          should notify("must_only_ever_contain: Array#<<(nil)"\
            "\nnil.must_be, but is NilClass in container"\
            " [1, 2, 3, 4, nil]")
        end
      end
      
      describe "#[]=" do
        context "when called with index" do
          it "should not notify if obj is non-nil" do
            subject[2] = 5
            should_not notify
          end

          it "should notify if obj is nil" do
            subject[2] = nil
            should notify
          end
        end
        
        context "when called with start and length" do
          it "should not notify if obj is non-nil" do
            subject[2, 2] = 5
            should_not notify
          end
          
          it "should not notify if obj is nil" do
            subject[2, 2] = nil
            should_not notify
          end
          
          it "should not notify if obj is compact array" do
            subject[2, 2] = [8, 9, 0]
          end
          
          it "should notify if obj is array containing nil" do
            subject[2, 2] = [8, nil, 0]
            should notify("must_only_ever_contain:"\
              " Array#[]=(2, 2, [8, nil, 0])\nnil.must_be, but is NilClass in"\
              " container [1, 2, 8, nil, 0]")
          end
        end
        
        context "when called with range" do
          it "should not notify if obj is non-nil obj" do
            subject[2..4] = 5
            should_not notify
          end
          
          it "should not notify if obj is nil" do
            subject[2..4] = nil
            should_not notify
          end
          
          it "should not notify if obj is compact array" do
            subject[2..4] = [8, 9, 0]
          end
          
          it "should notify if obj is array containing nil" do
            subject[2..4] = [8, nil, 0]
            should notify
          end
        end
      end
      
      describe "#collect!" do
        it "should not notify if all new values are non-nil" do
          subject.collect! {|v| v }
          should_not notify
        end
        
        it "should notify if any new values are nil" do
          subject.collect! {|v| v == 3 ? nil : v }
          should notify
        end
      end
      
      describe "#map!" do
        it "should not notify if all new values are non-nil" do
          subject.map! {|v| v }
          should_not notify
        end
        
        it "should notify if any new values are nil" do
          subject.map! {|v| v == 3 ? nil : v }
          should notify("must_only_ever_contain: Array#map! {}"\
            "\nnil.must_be, but is NilClass in container [1, 2, nil, 4]")
        end
      end
      
      describe "#concat" do
        it "should not notify if all items in other_array are non-nil" do
          subject.concat([6, 7, 8, 9])
          should_not notify
        end
        
        it "should notify if any item in other_array is nil" do
          subject.concat([6, 7, nil, 9])
          should notify
        end
      end
      
      describe "#fill" do
        context "when called without a block" do
          it "should not notify if obj is non-nil" do
            subject.fill(3)
            should_not notify
          end

          it "should notify if obj is nil" do
            subject.fill(nil)
            should notify("must_only_ever_contain: Array#fill(nil)"\
              "\nnil.must_be, but is NilClass in container"\
              " [nil, nil, nil, nil]")
          end
        end
        
        context "when called with a block" do
          it "should not notify if block never returns nil" do
            subject.fill {|v| v }
            should_not notify
          end

          it "should notify if block ever returns nil" do
            subject.fill {|v| v == 3 ? nil : v }
            should notify
          end
        end
      end
      
      describe "#flatten!" do
        it "should not notify if does not contain an array with nil items" do
          subject << [[6, 7], [8, 9]]
          subject.flatten!          
          should_not notify
        end
        
        it "should notify if contains an array with any nil items" do
          subject << [[6, 7], [nil, 9]]
          subject.flatten!
          should notify
        end
      end
      
      describe "#insert" do
        it "should not notify if all objs are non-nil" do
          subject.insert(2, 6, 7, 8, 9)
          should_not notify
        end
        
        it "should notify if any objs are nil" do
          subject.insert(2, 6, 7, nil, 9)
          should notify
        end
      end
      
      describe "#push" do
        it "should not notify if all objs are non-nil" do
          subject.push(6, 7, 8, 9)
          should_not notify
        end
        
        it "should notify if any objs are nil" do
          subject.push(6, 7, nil, 9)
          should notify("must_only_ever_contain: Array#push(6, 7, nil, 9)"\
            "\nnil.must_be, but is NilClass in container"\
            " [6, 7, nil, 9]")
        end
      end
      
      describe "#replace" do
        it "should not notify if all items in other_array are non-nil" do
          subject.replace([6, 7, 8, 9])
          should_not notify
        end
        
        it "should notify if any items in other_array are nil" do
          subject.replace([6, 7, nil, 9])
          should notify
        end
      end
      
      describe "#unshift" do
        it "should not notify if all objs are non-nil" do
          subject.unshift(6, 7, 8, 9)
          should_not notify
        end
        
        it "should notify if any objs are nil" do
          subject.unshift(6, 7, nil, 9)
          should notify
        end
      end
    end
    
    describe Hash do
      subject { {} }
      
      context "when called with no arguments" do
        before do
          subject.must_only_ever_contain
        end
        
        example "must_only_ever_contain_cases should == []" do
          subject.must_only_ever_contain_cases.should == []
        end
        
        it "should notify if inserting a nil value" do
          subject[:nil] = nil
          should notify
        end
        
        it "should notify if inserting a false key" do
          subject[false] = :false
          should notify("must_only_ever_contain: Hash#[]=(false, :false)"\
            "\npair {false=>:false} does not match [] in container"\
            " {false=>:false}")
        end
        
        it "should not notify if inserting a regular pair" do
          subject[:key] = :value
          should_not notify
        end
      end
      
      context "when called with a hash" do
        before do
          subject.must_only_ever_contain(Symbol => Integer, Integer => Symbol)
        end
        
        it "should notify if inserting a non-matching key" do
          subject["six"] = 6
          subject["six"].should == 6
          should notify("must_only_ever_contain: Hash#[]=(\"six\", 6)"\
            "\npair {\"six\"=>6} does not match"\
            " [{Symbol=>Integer, Integer=>Symbol}] in container {\"six\"=>6}")
        end
        
        it "should notify if inserting a matching value" do
          subject[:six] = :six
          subject[:six].should == :six
          should notify
        end
        
        it "should not notify if inserting a non-matching pair" do
          subject[:six] = 6
          subject[:six].should == 6
          should_not notify
        end
        
        it "should not notify if replaced with an acceptable hash" do
          subject[:six] = 6
          subject.replace({:sym => 343}).should == subject
          subject[:six].should be_nil
          subject[:sym].should == 343
          should_not notify
        end
        
        it "should notify if merged with an unacceptable hash" do
          subject.merge!({3 => 1})
          should notify("must_only_ever_contain: Hash#merge!({3=>1})"\
            "\npair {3=>1} does not match"\
            " [{Symbol=>Integer, Integer=>Symbol}] in container {3=>1}")
        end
        
        it "should not notify if updated with an acceptable hash" do
          subject.update({:yes => 1})
          should_not notify
        end
      end
      
      describe "#must_only_ever_contain_cases" do
        before do
          subject.must_only_ever_contain(Symbol => Symbol)
        end
        
        example "must_only_ever_contain_cases should == [{Symbol => Symbol}]" do
          subject.must_only_ever_contain_cases.should == [{Symbol => Symbol}]
        end
                
        it "should not notify if inserting Symbol => Symbol pair" do
          subject[:hello] = :granny
          should_not notify
        end
        
        it "should notify if inserting Symbol => Integer pair" do
          subject[:hello] = 970
          should notify
        end
        
        it "should notify if inserting Integer => Integer pair" do
          subject[3984] = 970
          should notify("must_only_ever_contain: Hash#[]=(3984, 970)"\
            "\npair {3984=>970} does not match [{Symbol=>Symbol}] in"\
            " container {3984=>970}")
        end
        
        context "when #must_only_ever_contain_cases is updated" do
          let(:cases) { [{Symbol => Symbol}, {Symbol => Integer}] }
          
          before do
            subject.must_only_ever_contain_cases = cases
          end
          
          example "must_only_ever_contain_cases should =="\
              " [{Symbol => Symbol}, {Symbol => Integer}]" do
            subject.must_only_ever_contain_cases.should == cases
          end
          
          it "should not notify if inserting Symbol => Symbol pair" do
            subject[:hello] = :granny
            should_not notify
          end

          it "should not notify if inserting Symbol => Integer pair" do
            subject[:hello] = 970
            should_not notify
          end

          it "should notify if inserting Integer => Integer pair" do
            subject[3984] = 970
            should notify
          end
        end
      end
      
      context "when it is initially non-empty" do
        before do
          subject[:hello] = :world
        end
        
        it "should not notify if any cases match" do
          subject.must_only_ever_contain(Symbol => Symbol)
          should_not notify
        end
        
        it "should notify if cases do not match" do
          subject.must_only_ever_contain(Symbol => String)
          should notify("must_only_ever_contain: pair {:hello=>:world} does"\
            " not match [{Symbol=>String}] in container {:hello=>:world}")
        end
      end
    end
        
    describe "custom" do
      it_should_behave_like "custom MustOnlyEverContain"
      
      context "without MustOnlyEverContain.registered_class" do
        describe "#must_only_contain" do
          it "should use each to check the contents" do
            subject.must_only_contain(String)
            subject.should be_each_called
            should notify
          end
        end
        
        describe "#must_only_ever_contain" do
          it "should raise a TypeError" do
            expect do
              subject.must_only_ever_contain(Symbol)
            end.should raise_error(TypeError,
              /No MustOnlyEverContain.registered_class for .*Box/)
          end
        end
      end
      
      context "with MustOnlyEverContain.registered_class" do
        register_before_and_unregister_after
        
        context "when subject already has singleton methods" do
          it "should raise ArgumentError" do
            expect do
              class <<subject
                def singleton_method
                end
              end
              subject.must_only_ever_contain(Symbol)
            end.should raise_error(ArgumentError,
              /must_only_ever_contain adds singleton methods but receiver .*/)
          end
        end
        
        context "when updating contents" do
          it "should notify if does not match must_only_ever_contain_cases" do
            subject.must_only_ever_contain(Symbol)
            subject.contents = 435
            should notify
          end
          
          it "should not notify if matches must_only_ever_contain_cases" do
            subject.must_only_ever_contain(Symbol)
            subject.contents = :another_symbol
            should_not notify
          end
        end
        
        context "when emptied" do
          it "should notify if nil does not match"\
              " must_only_ever_contain_cases" do
            subject.must_only_ever_contain(Symbol)
            subject.empty!
            subject.should_not be_each_called
            should notify
          end
        end
        
        describe "ArgumentError" do
          it "should raise when trying to register a non-class" do
            expect do
              MustOnlyEverContain.register(:not_a_class)
            end.should raise_error(ArgumentError)
          end
          
          it "should raise when trying to register a class more than once" do
            expect do
              MustOnlyEverContain.register(Box)
            end.should raise_error(ArgumentError)
          end
        end
      end
    end
  end
  
  describe "#must_never_ever_contain" do
    describe Array do
      subject { [nil] }
      
      before do
        subject.must_never_ever_contain
      end
      
      it "should notify if initially contains a matching item" do
        array = [:oops]
        array.must_never_ever_contain
        should notify("must_never_ever_contain: :oops.must_not_be, but is"\
          " Symbol in container [:oops]")
      end
      
      describe "#<<" do
        it "should not notify if obj is nil" do
          subject << nil
          should_not notify
        end

        it "should notify if obj is non-nil" do
          subject << 5
          should notify("must_never_ever_contain: Array#<<(5)"\
            "\n5.must_not_be, but is Fixnum in container"\
            " [nil, 5]")
        end
      end
      
      describe "#collect!" do
        it "should not notify if all new values are nil" do
          subject.collect! {|v| v }
          should_not notify
        end

        it "should notify if any new values are non-nil" do
          subject.collect! {|v| 5 }
          should notify
        end
      end      
    end
    
    describe Hash do
      subject { {} }
      
      context "when called with a hash" do
        before do
          subject.must_never_ever_contain(Symbol => Integer, Integer => Symbol)
        end
        
        it "should notify if inserting a non-matching value" do
          subject[:six] = 6
          subject[:six].should == 6
          should notify
        end
    
        it "should not notify if inserting a matching pair" do
          subject[:six] = :six
          subject[:six].should == :six
          should_not notify
        end        
      end
      
      context "when it is initially non-empty" do
        before do
          subject[:hello] = :world
        end
    
        it "should not notify if no cases match" do
          subject.must_never_ever_contain(Symbol => String)
          should_not notify
        end
    
        it "should notify if any cases match" do
          subject.must_never_ever_contain(Symbol => Symbol)
          should notify("must_never_ever_contain: pair {:hello=>:world}"\
            " matches [{Symbol=>Symbol}] in container {:hello=>:world}")
        end
      end
    end
    
    describe "custom" do
      it_should_behave_like "custom MustOnlyEverContain"
      
      describe "without MustOnlyEverContain.registered_class" do
        describe "#must_not_contain" do
          it "should use each to check the contents" do
            subject.must_not_contain(Symbol)
            subject.should be_each_called
            should notify
          end
        end

        describe "#must_never_ever_contain" do
          it "should raise a TypeError" do
            expect do
              subject.must_never_ever_contain(String)
            end.should raise_error(TypeError,
              /No MustOnlyEverContain.registered_class for .*Box/)
          end
        end
      end
      
      describe "with MustOnlyEverContain.registered_class" do
        register_before_and_unregister_after
        
        context "when subject already has singleton methods" do
          it "should raise ArgumentError" do
            expect do
              class <<subject
                def singleton_method
                end
              end
              subject.must_never_ever_contain(Symbol)
            end.should raise_error(ArgumentError,
              /must_never_ever_contain adds singleton methods but receiver .*/)
          end
        end
                
        context "when updating contents" do
          it "should notify if matches must_only_ever_contain_cases" do
            subject.must_only_ever_contain(Numeric)
            subject.contents = 435
            should notify
          end

          it "should not notify if does not match"\
              " must_only_ever_contain_cases" do
            subject.must_never_ever_contain(Numeric)
            subject.contents = :another_symbol
            should_not notify
          end
        end

        context "when emptied" do
          it "should notify if nil matches must_never_ever_contain_cases" do
            subject.must_never_ever_contain(nil)
            subject.empty!
            subject.should_not be_each_called
            should notify
          end
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

seperate into multiple files, refactor, remove excess duplication, improve names of helper functions (*_helper), set their visibility to private?

rdoc (focus on examples)

=end