require 'spec_helper'

describe MustBe do
  include MustBeExampleHelper
  
  describe ContainerNote do
    describe '#backtrace' do
      context "when #must_only_ever_contain has been called" do
        subject do
          note = ContainerNote.new(Note.new("nothing"),
            [].must_only_ever_contain)
          note.set_backtrace([])
          note
        end
    
        its(:backtrace) { should include("=== caused by container ===")}
      end
    
      context "when #must_only_ever_contain has not been called" do
        subject do
          note = ContainerNote.new(Note.new("nothing"), [])
          note.set_backtrace([])
          note
        end
    
        its(:backtrace) { should_not include("=== caused by container ===")}
      end
    end
  end
  
  describe '#must_only_contain' do
    context "when called on an array" do
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
        it "should notify if any member is false or nil" do
          [false, nil].must_only_contain
          should notify
        end
      
        it "should not notify if every member is neither false nor nil" do
          [0, [], ""].must_only_contain
          should_not notify
        end
      end
    end
    
    describe "when called on a hash" do
      subject { {:key => :value, :another => 'thing', 12 => 43} }
      
      describe "note message" do
        it "should include \"does not match\"" do
          subject = {:key => :value}
          subject.must_only_contain(Symbol => [String, Numeric])
          should notify("must_only_contain: pair {:key=>:value} does"\
            " not match [{Symbol=>[String, Numeric]}] in container"\
            " {:key=>:value}")
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
  
  describe '#must_not_contain' do
    context "when called on an array" do
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
        it "should not notify if every member is false or nil" do
          [false, nil].must_not_contain
          should_not notify
        end
      
        it "should notify if any member is neither false nor nil" do
          [0, [], ""].must_not_contain
          should notify
        end
      end
    end
    
    context "when called on a hash" do
      subject { {:key => :value, :another => 'thing', 12 => 43} }
      
      context "when called with no arguments" do
        it "should not notifiy if every key and value"\
            " is false or nil" do
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
            must_check_member(contents)
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
  
  describe '#must_only_ever_contain' do
    context "when called on an array" do
      subject { [1, 2, 3, 4] }
      
      before do
        subject.must_only_ever_contain
      end
      
      it "should notify if initially contains a non-matching member" do
        array = [:oops]
        array.must_only_ever_contain(String)
        should notify("must_only_ever_contain: :oops.must_be(String), but is"\
          " Symbol in container [:oops]")
      end
      
      context "after disabling" do
        before do
          @enabled_array = [].must_only_ever_contain(Fixnum)
        end
        
        before_disable_after_enable
        
        context "when #must_only_ever_contain was called while still"\
            " enabled" do
          it "should not notify" do
            @enabled_array << 3.2
            should_not notify
          end
          
          it "should continue to have singleton methods" do
            @enabled_array.singleton_methods.should_not be_empty
          end
          
          context "after being re-enabled" do
            before do
              MustBe.enable
            end
            
            it "should notify again" do
              @enabled_array << 3.2
              should notify(/must_only_ever_contain: Array#<<\(3.2\)/)
            end
          end          
        end
        
        context "when #must_only_ever_contain is called" do
          before do 
            @disabled_array = [].must_only_ever_contain(Fixnum)
          end
          
          it "should not notify" do
            @disabled_array << 3.2
            should_not notify
          end
          
          it "should not have singleton methods" do
            @disabled_array.singleton_methods.should be_empty
          end
          
          context "after being re-enabled" do
            before do
              MustBe.enable
            end
            
            it "should still not notify" do
              @disabled_array << 3.2
              should_not notify
            end
          end
        end
      end
      
      describe '#<<' do
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
      
      describe '#[]=' do
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
              " Array#[]=(2, 2, [8, nil, 0])\nnil.must_be,"\
              " but is NilClass in"\
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
      
      describe '#collect!' do
        it "should not notify if all new values are non-nil" do
          subject.collect! {|v| v }
          should_not notify
        end
        
        it "should notify if any new values are nil" do
          subject.collect! {|v| v == 3 ? nil : v }
          should notify
        end
      end
      
      describe '#map!' do
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
      
      describe '#concat' do
        it "should not notify if all members in other_array are non-nil" do
          subject.concat([6, 7, 8, 9])
          should_not notify
        end
        
        it "should notify if any member in other_array is nil" do
          subject.concat([6, 7, nil, 9])
          should notify
        end
      end
      
      describe '#fill' do
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
      
      describe '#flatten!' do
        it "should not notify if does not contain an array with"\
            " nil members" do
          subject << [[6, 7], [8, 9]]
          subject.flatten!          
          should_not notify
        end
        
        it "should notify if contains an array with any nil members" do
          subject << [[6, 7], [nil, 9]]
          subject.flatten!
          should notify
        end
      end
      
      describe '#insert' do
        it "should not notify if all objs are non-nil" do
          subject.insert(2, 6, 7, 8, 9)
          should_not notify
        end
        
        it "should notify if any objs are nil" do
          subject.insert(2, 6, 7, nil, 9)
          should notify
        end
      end
      
      describe '#push' do
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
      
      describe '#replace' do
        it "should not notify if all members in other_array are non-nil" do
          subject.replace([6, 7, 8, 9])
          should_not notify
        end
        
        it "should notify if any members in other_array are nil" do
          subject.replace([6, 7, nil, 9])
          should notify
        end
      end
      
      describe '#unshift' do
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
    
    context "when called on a hash" do
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
      
      describe '#must_only_ever_contain_cases' do
        before do
          subject.must_only_ever_contain(Symbol => Symbol)
        end
        
        example "must_only_ever_contain_cases"\
            " should == [{Symbol => Symbol}]" do
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
        describe '#must_only_contain' do
          it "should use each to check the contents" do
            subject.must_only_contain(String)
            subject.should be_each_called
            should notify
          end
        end
        
        describe '#must_only_ever_contain' do
          it "should raise TypeError" do
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
        
        describe "when called with bad arguments" do
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
  
  describe '#must_never_ever_contain' do
    context "when called on an array" do
      subject { [nil] }
      
      before do
        subject.must_never_ever_contain
      end
      
      it "should notify if initially contains a matching member" do
        array = [:oops]
        array.must_never_ever_contain
        should notify("must_never_ever_contain: :oops.must_not_be, but is"\
          " Symbol in container [:oops]")
      end
      
      describe '#<<' do
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
      
      describe '#collect!' do
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
    
    context "when called on a hash" do
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
        describe '#must_not_contain' do
          it "should use each to check the contents" do
            subject.must_not_contain(Symbol)
            subject.should be_each_called
            should notify
          end
        end

        describe '#must_never_ever_contain' do
          it "should raise TypeError" do
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
              /must_never_ever_contain adds singleton methods but .*/)
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
