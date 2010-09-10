require 'spec_helper'

describe MustBe do
  include MustBeExampleHelper
  
  ### Short Inspect ###
  
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
        " MustBe::SHORT_INSPECT_CUTOFF_LENGTH" do
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
      should notify(/"x*\.\.\.x*"\.must_be\(Symbol\), but matches String/)
    end
  end
  
  ### Enable ###

  describe ".disable" do    
    before_disable_after_enable
    
    it "should be disabled" do
      MustBe.should_not be_enabled
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
    
    it "should be idempotent" do
      MustBe.disable
      MustBe.should_not be_enabled
    end
  end

  describe ".enable" do
    it "should start off enabled" do
      MustBe.should be_enabled
    end
    
    context "after disabling" do
      before_disable_and_reenable
      
      it "should re-enable" do
        MustBe.should be_enabled
      end
      
      example "#must_be should notify" do
        5799.must_be(:lolly).should == 5799
        should notify("5799.must_be(:lolly), but matches Fixnum")
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
      
      it "should be idempotent" do
        MustBe.enable
        MustBe.should be_enabled
      end
    end
  end
  
  describe ".register_disabled_method" do
    before :all do
      module ::MustBe
        def must_try_register_disabled_method
          :enabled
        end
        
        def must_try_register_disabled_method__disabled
          :disabled
        end
        
        register_disabled_method(
          :must_try_register_disabled_method__disabled)
      
        register_disabled_method(:must_try_register_disabled_method,
          :must_try_register_disabled_method__disabled)
      end      
    end
            
    context "after disabling" do
      before_disable_after_enable
      
      example "#must_try_register_disabled_method should be disabled" do
        must_try_register_disabled_method.should == :disabled
      end
    end
    
    context "after re-enabling" do
      before_disable_and_reenable
      
      example "#must_try_register_disabled_method should return :enabled" do
        must_try_register_disabled_method.should == :enabled
      end
    end
  end
  
  describe ".register_disabled_handler" do    
    before do
      @original_disabled_handlers = 
        MustBe.send(:class_variable_get, :@@disabled_handlers).clone
      
      @handler_called = nil
      @handler = lambda do |enabled|
        @handler_called = enabled
      end
    end
    
    after do
      MustBe.send(:class_variable_set, :@@disabled_handlers, 
        @original_disabled_handlers)
    end
    
    context "when initially enabled" do
      before do
        MustBe.register_disabled_handler(&@handler)
      end
      
      example "handler should not be called immediately" do
        @handler_called.should be_nil
      end
      
      context "when disabled" do
        before_disable_after_enable
        
        example "handler should be called" do
          @handler_called.should be_false
        end
      end
    end
    
    context "when initially disabled" do
      before_disable_after_enable
      
      before do
        MustBe.register_disabled_handler(&@handler)
      end
      
      example "handler should be called immediately" do
        @handler_called.should be_false
      end
      
      context "when enabled" do
        before do
          MustBe.enable
        end
        
        example "handler should be called" do
          @handler_called.should be_true
        end
      end
    end
  end
  
  describe '#must_just_return' do
    it "should return the receiver" do
      :gnarly.must_just_return(:args, :ignored).should == :gnarly
      should_not notify
    end
  end
  
  describe '#must_just_yield' do
    it "should yield" do
      did_yield = false
      must_just_yield { did_yield = true }
      did_yield.should be_true
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
  
  describe '#must_notify' do
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
        
    context "when called with no arguments" do
      subject { must_notify }
      it_should_notify("MustBe::Note")
      its_assertion_properties_should_be_nil
    end
    
    context "when called with single (message) argument" do
      subject { must_notify("message for note") }
      it_should_notify("message for note")
      its_assertion_properties_should_be_nil
    end
    
    context "when called with existing note" do
      note = Note.new("existing note")
      
      subject { must_notify(note) }
      it_should_notify("existing note")
      it { should == note }
    end
    
    context "when called with receiver and assertion" do
      subject { must_notify(4890, :must_be_silly) }
      it_should_notify("4890.must_be_silly")
      its(:receiver) { should == 4890 }
      its(:assertion) { should == :must_be_silly }
      its(:args) { should be_nil }
      its(:block) { should be_nil }
    end
    
    context "when called with receiver, assertion, and an argument" do
      subject { must_notify(4890, :must_be_silly, [57]) }
      it_should_notify("4890.must_be_silly(57)")
      its(:receiver) { should == 4890 }
      its(:assertion) { should == :must_be_silly }
      its(:args) { should == [57] }
      its(:block) { should be_nil }
    end
    
    context "when called with receiver, assertion, and arguments" do
      subject { must_notify(4890, :must_be_silly, [57, 71]) }
      it_should_notify("4890.must_be_silly(57, 71)")
      its(:receiver) { should == 4890 }
      its(:assertion) { should == :must_be_silly }
      its(:args) { should == [57, 71] }
      its(:block) { should be_nil }
    end
    
    context "when called with receiver, assertion, and block" do
      block = lambda { nil }
      
      subject { must_notify(4890, :must_be_silly, nil, block) }
      it_should_notify("4890.must_be_silly {}")
      its(:receiver) { should == 4890 }
      its(:assertion) { should == :must_be_silly }
      its(:args) { should == nil }
      its(:block) { should == block }
    end
    
    context "when called with receiver, assertion, arguments, and block" do
      subject { must_notify(4890, :must_be_silly, [57, 71], block) }
      it_should_notify("4890.must_be_silly(57, 71) {}")
      its(:receiver) { should == 4890 }
      its(:assertion) { should == :must_be_silly }
      its(:args) { should == [57, 71] }
      its(:block) { should == block }
    end
    
    context "when called with #additional_message" do
      subject do
        must_notify(5, :must_be, [String], nil, ", but matches Fixnum")
      end
      
      it_should_notify("5.must_be(String), but matches Fixnum")
      its(:receiver) { should == 5 }
      its(:assertion) { should == :must_be }
      its(:args) { should == [String] }
      its(:block) { should be_nil }
      its(:additional_message) { should == ", but matches Fixnum"}
    end
  end
  
  describe '#must_check' do
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
end