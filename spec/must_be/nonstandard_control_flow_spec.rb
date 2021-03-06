require 'spec_helper'

describe MustBe do
  include MustBeExampleHelper
  
  shared_examples_for "*_raise in case of bad arguments" do
    context "when called with an exception type and something other"\
        " than nil, a string, or a regexp" do
      it "should raise TypeError" do
        expect do
          :it.send(the_method_name, RangeError, :not_nil_string_or_regexp) {}
        end.to raise_error(TypeError, "nil, string, or regexp required")
      end
    end
    
    context "when called with more than two arguments" do
      it "should raise ArgumentError" do
        expect do
          :it.send(the_method_name, RangeError, "message", "trouble") {}
        end.to raise_error(ArgumentError,
          "wrong number of arguments (3 for 2)")
      end
    end
    
    context "when called with two string arguments" do
      it "should raise TypeError" do
        expect do
          :it.send(the_method_name, "message", "second_message") {}
        end.to raise_error(TypeError, "exception class expected")
      end
    end
    
    context "when called with a class which does not extend Exception" do
      it "should raise TypeError" do
        expect do
          :it.send(the_method_name, Range) {}
        end.to raise_error(TypeError, "exception class expected")
      end
    end
    
    context "when called with something other than an exception type,"\
        " nil, string, or regexp" do
      it "should raise TypeError" do
        expect do
          :it.send(the_method_name, :not_an_error_type) {}
        end.to raise_error(TypeError,
          "exception class expected")
      end
    end
  end
  
  describe '#must_raise' do
    let(:the_method_name) { :must_raise }
    it_should_behave_like "*_raise in case of bad arguments"
    
    context "when called with no arguments" do
      it "should not notify if any exception is raised" do
        expect do
          :it.must_raise { raise Exception }
        end.to raise_error(Exception)
        should_not notify
      end
      
      it "should notify if no exception is raised" do
        called = false
        :it.must_raise{called = true; :result}.should == :result
        called.should be true
        should notify(":it.must_raise {}, but nothing was raised")
      end
    end
    
    context "when called with an exception type" do
      it "should not notify if an exception of the same type is raised" do
        expect do
          :it.must_raise(TypeError) { raise TypeError }
        end.to raise_error(TypeError)
        should_not notify
      end
      
      it "should notify if no exception is raised" do
        :it.must_raise(TypeError) {}
        should notify(":it.must_raise(TypeError) {}, but nothing was raised")
      end
      
      it "should notify if a different exception type is raised" do
        expect do
          :it.must_raise(TypeError) { raise ArgumentError }
        end.to raise_error(ArgumentError)
        should notify(":it.must_raise(TypeError) {},"\
          " but ArgumentError was raised")
      end
    end
    
    context "when called with a string" do
      it "should not notify if an exception with the same message is"\
          " raised" do
        expect do
          :it.must_raise("message") { raise "message" }
        end.to raise_error(RuntimeError)
        should_not notify
      end
      
      it "should notify if no exception is raised" do
        :it.must_raise("message") {}
        should notify(":it.must_raise(\"message\") {}, but nothing"\
          " was raised")
      end
      
      it "should notify if an exception with a different message is raised" do
        expect do
          :it.must_raise("message") { raise "wrong" }
        end.to raise_error(RuntimeError)
        should notify(":it.must_raise(\"message\") {},"\
          " but RuntimeError with message \"wrong\" was raised")
      end
    end
    
    context "when called with a regexp" do
      it "should not notify if an exception with matching message is"\
          " raised" do
        expect do
          :it.must_raise(/message/) { raise "some message" }
        end.to raise_error(RuntimeError)
        should_not notify
      end
      
      it "should notify if no exception is raised" do
        :it.must_raise(/message/) {}
        should notify(":it.must_raise(/message/) {}, but nothing was raised")
      end
      
      it "should notify if an exception with non-matching message"\
          " is raised" do
        expect do
          :it.must_raise(/message/) { raise "mess" }
        end.to raise_error(RuntimeError)
        should notify(":it.must_raise(/message/) {},"\
          " but RuntimeError with message \"mess\" was raised")
      end
    end
    
    context "when called with nil" do
      it "should not notify if any exception is raised" do
        expect do
          :it.must_raise(nil) { raise Exception }
        end.to raise_error(Exception)
        should_not notify
      end
      
      it "should notify if no exception is raised" do
        :it.must_raise(nil) {}
        should notify(":it.must_raise(nil) {}, but nothing was raised")
      end
    end
    
    context "when called with an exception type and a string" do
      it "should not notify if an exception of the same type with"\
          " the same message is raised" do
        expect do
          :it.must_raise(TypeError, "oops") { raise TypeError, "oops" }
        end.to raise_error(TypeError)
        should_not notify
      end
      
      it "should notify if no exception is raised" do
        :it.must_raise(TypeError, "oops") {}
        should notify(":it.must_raise(TypeError, \"oops\") {},"\
          " but nothing was raised")
      end
      
      it "should notify if an exception of a different type is raised" do
        expect do
          :it.must_raise(TypeError, "oops") { raise ArgumentError, "wrong" }
        end.to raise_error(ArgumentError)
        should notify(":it.must_raise(TypeError, \"oops\") {},"\
          " but ArgumentError was raised")
      end
      
      it "should notify if an exception of the same type"\
          " but with a different message is raised" do
        expect do
          :it.must_raise(TypeError, "oops") { raise TypeError, "wrong" }
        end.to raise_error(TypeError)
        should notify(":it.must_raise(TypeError, \"oops\") {},"\
          " but TypeError with message \"wrong\" was raised")
      end
    end
    
    context "when called with an exception type and a regexp" do
      it "should not notify if an exception of the same type with"\
          " matching message is raised" do
        expect do
          :it.must_raise(TypeError, /oops/) { raise TypeError, "oops" }
        end.to raise_error(TypeError)
        should_not notify
      end
      
      it "should notify if no exception is raised" do
        :it.must_raise(TypeError, /oops/) {}
        should notify(":it.must_raise(TypeError, /oops/) {},"\
          " but nothing was raised")
      end
      
      it "should notify if an exception of a different type is raised" do
        expect do
          :it.must_raise(TypeError, /oops/) { raise ArgumentError, "wrong" }
        end.to raise_error(ArgumentError)
        should notify(":it.must_raise(TypeError, /oops/) {},"\
          " but ArgumentError was raised")
      end
      
      it "should notify if an exception of the same type"\
          " but with a non-matching message is raised" do
        expect do
          :it.must_raise(TypeError, /oops/) { raise TypeError, "wrong" }
        end.to raise_error(TypeError)
        should notify(":it.must_raise(TypeError, /oops/) {},"\
          " but TypeError with message \"wrong\" was raised")
      end
    end
    
    context "when called with an exception type and nil" do
      it "should not notify if an exception of the same type is raised" do
        expect do
          :it.must_raise(TypeError, nil) { raise TypeError }
        end.to raise_error(TypeError)
        should_not notify
      end
      
      it "should notify if no exception is raised" do
        :it.must_raise(TypeError, nil) {}
        should notify(":it.must_raise(TypeError, nil) {},"\
          " but nothing was raised")
      end
      
      it "should notify if a different exception type is raised" do
        expect do
          :it.must_raise(TypeError, nil) { raise ArgumentError }
        end.to raise_error(ArgumentError)
        should notify(":it.must_raise(TypeError, nil) {},"\
          " but ArgumentError was raised")
      end
    end
    
    describe "after disabled" do
      before_disable_after_enable
      
      it "should just yield" do
        did_yield = false
        :it.must_raise { did_yield = true }
        did_yield.should be true
      end
    end
  end
  
  describe '#must_not_raise' do
    let(:the_method_name) { :must_not_raise }
    it_should_behave_like "*_raise in case of bad arguments"
    
    context "when called with no arguments" do
      it "should notify if any exception is raised" do
        expect do
          :it.must_not_raise { raise Exception }
        end.to raise_error(Exception)
        should notify(":it.must_not_raise {}, but raised Exception")
      end
      
      it "should not notify if no exception is raised" do
        called = false
        :it.must_not_raise {called = true; :result}.should == :result
        called.should be true
        should_not notify
      end
    end
    
    context "when called with an exception type" do
      it "should notify if an exception of the same type is raised" do
        expect do
          :it.must_not_raise(TypeError) { raise TypeError }
        end.to raise_error(TypeError)
        should notify(":it.must_not_raise(TypeError) {},"\
          " but raised TypeError")
      end
      
      it "should not notify if no exception is raised" do
        :it.must_not_raise(TypeError) {}
        should_not notify
      end
      
      it "should not notify if a different exception type is raised" do
        expect do
          :it.must_not_raise(TypeError) { raise ArgumentError }
        end.to raise_error(ArgumentError)
        should_not notify
      end
    end
    
    context "when called with a string" do
      it "should notify if an exception with the same message is raised" do
        expect do
          :it.must_not_raise("message") { raise "message" }
        end.to raise_error(RuntimeError)
        should notify(":it.must_not_raise(\"message\") {},"\
          " but raised RuntimeError with message \"message\"")
      end
      
      it "should not notify if no exception is raised" do
        :it.must_not_raise("message") {}
        should_not notify
      end
      
      it "should not notify if an exception with a different message is"\
          " raised" do
        expect do
          :it.must_not_raise("message") { raise "wrong" }
        end.to raise_error(RuntimeError)
        should_not notify
      end
    end
    
    context "when called with a regexp" do
      it "should notify if an exception with matching message is raised" do
        expect do
          :it.must_not_raise(/message/) { raise "some message" }
        end.to raise_error(RuntimeError)
        should notify(":it.must_not_raise(/message/) {},"\
          " but raised RuntimeError with message \"some message\"")
      end
      
      it "should not notify if no exception is raised" do
        :it.must_not_raise(/message/) {}
        should_not notify
      end
      
      it "should not notify if an exception with non-matching message"\
          " is raised" do
        expect do
          :it.must_not_raise(/message/) { raise "mess" }
        end.to raise_error(RuntimeError)
        should_not notify
      end
    end
    
    context "when called with nil" do
      it "should notify if any exception is raised" do
        expect do
          :it.must_not_raise(nil) { raise Exception }
        end.to raise_error(Exception)
        should notify(":it.must_not_raise(nil) {}, but raised Exception")
      end
      
      it "should not notify if no exception is raised" do
        :it.must_not_raise(nil) {}
        should_not notify
      end
    end
    
    context "when called with an exception type and a string" do
      it "should notify if an exception of the same type with"\
          " the same message is raised" do
        expect do
          :it.must_not_raise(TypeError, "oops") { raise TypeError, "oops" }
        end.to raise_error(TypeError)
        should notify(":it.must_not_raise(TypeError, \"oops\") {},"\
          " but raised TypeError with message \"oops\"")
      end
      
      it "should not notify if no exception is raised" do
        :it.must_not_raise(TypeError, "oops") {}
        should_not notify
      end
      
      it "should not notify if an exception of a different type is raised" do
        expect do
          :it.must_not_raise(TypeError, "oops") { raise ArgumentError, "grr" }
        end.to raise_error(ArgumentError)
        should_not notify
      end
      
      it "should not notify if an exception of the same type"\
          " but with a different message is raised" do
        expect do
          :it.must_not_raise(TypeError, "oops") { raise TypeError, "wrong" }
        end.to raise_error(TypeError)
        should_not notify
      end
    end
    
    context "when called with an exception type and a regexp" do
      it "should notify if an exception of the same type with"\
          " matching message is raised" do
        expect do
          :it.must_not_raise(TypeError, /oops/) { raise TypeError, "oops" }
        end.to raise_error(TypeError)
        should notify(":it.must_not_raise(TypeError, /oops/) {},"\
          " but raised TypeError with message \"oops\"")
      end
      
      it "should not notify if no exception is raised" do
        :it.must_not_raise(TypeError, /oops/) {}
        should_not notify
      end
      
      it "should not notify if an exception of a different type is raised" do
        expect do
          :it.must_not_raise(TypeError, /oops/) { raise ArgumentError, "grr" }
        end.to raise_error(ArgumentError)
        should_not notify
      end
      
      it "should not notify if an exception of the same type"\
          " but with a non-matching message is raised" do
        expect do
          :it.must_not_raise(TypeError, /oops/) { raise TypeError, "wrong" }
        end.to raise_error(TypeError)
        should_not notify
      end
    end
    
    context "when called with an exception type and nil" do
      it "should notify if an exception of the same type is raised" do
        expect do
          :it.must_not_raise(TypeError, nil) { raise TypeError }
        end.to raise_error(TypeError)
        should notify(":it.must_not_raise(TypeError, nil) {},"\
          " but raised TypeError")
      end
      
      it "should not notify if no exception is raised" do
        :it.must_not_raise(TypeError, nil) {}
        should_not notify
      end
      
      it "should not notify if a different exception type is raised" do
        expect do
          :it.must_not_raise(TypeError, nil) { raise ArgumentError }
        end.to raise_error(ArgumentError)
        should_not notify
      end
    end
  end
  
  shared_examples_for "*_throw in case of bad arguments" do
    context "when called with more than two arguments" do
      it "should raise ArgumentError" do
        expect do
          :it.send(the_method_name, :symbol, :object, :other) {}
        end.to raise_error(ArgumentError,
          "wrong number of arguments (3 for 2)")
      end
    end
  end
  
  describe '#must_throw' do
    let(:the_method_name) { :must_throw }
    it_should_behave_like "*_throw in case of bad arguments"
    
    context "when block returns normally" do
      it "should notify and return the result" do
        :it.must_throw{:result}.should == :result
        should notify(":it.must_throw {}, but did not throw")
      end
    end
    
    context "when block throws exception" do
      it "should notify and reraise" do
        expect do
          :it.must_throw { raise }
        end.to raise_error(RuntimeError, "")
        should notify(":it.must_throw {}, but raised RuntimeError")
      end
      
      context "when MustBe.notifier raises" do
        before do
          @notifier = MustBe.notifier
          MustBe.notifier = lambda {|note| true }
        end
        
        after do
          MustBe.notifier = @notifier
        end
        
        it "should raise without transparently" do
          expect do
            :it.must_throw { raise }
          end.to raise_error(Note,
            ":it.must_throw {}, but raised RuntimeError")
        end
        
        it "should notify with proper message (Ruby 1.8 regession)" do
          # Otherwise, the problem does not show up.
          MustBe.send(:class_variable_set, :@@must_throw__installed, false)
          expect do
            :it.must_throw { throw :ball }
          end.to raise_error(Note, /:it.must_throw \{\}, but raised/)
        end
      end
    end
    
    context "when block throws uncaught symbol" do
      it "should notify and reraise" do
        expect do
          :it.must_throw { throw :uncaught }
        end.to raise_error(/uncaught throw/)
        if RUBY_VERSION < "1.9"
          should notify(":it.must_throw {}, but raised NameError")
        elsif RUBY_VERSION < "2.4"
          should notify(":it.must_throw {}, but raised ArgumentError")
        else
          should notify(":it.must_throw {}, but raised UncaughtThrowError")
        end
      end
    end
    
    context "when block throws" do
      context "when called with no arguments" do
        it "should not notify" do
          expect do
            :it.must_throw { throw :ball }
          end.to throw_symbol(:ball)
          should_not notify
        end
      end
      
      context "when called with tag" do
        it "should not notify if tag equals thrown tag" do
          expect do
            :it.must_throw(:ball) { throw :ball }
          end.to throw_symbol(:ball)
          should_not notify
        end
        
        it "should notify if tag does not equal thrown tag" do
          expect do
            :it.must_throw(:pie) { throw :ball }
          end.to throw_symbol(:ball)
          should notify(":it.must_throw(:pie) {}, but threw :ball")
        end
        
        context "when checked against object" do
          it "should notify" do
            expect do
              :it.must_throw(:ball, :fiercely) { throw :ball }
            end.to throw_symbol(:ball)
            should notify(":it.must_throw(:ball, :fiercely) {},"\
              " but threw :ball")
          end
          
          it "should notify even if checked object is nil" do
            expect do
              :it.must_throw(:ball, nil) { throw :ball }
            end.to throw_symbol(:ball)
            should notify(":it.must_throw(:ball, nil) {},"\
              " but threw :ball")
          end
        end
      end
      
      context "when called with tag and object" do
        it "should not notify if tag equals thrown tag and"\
            " object equals thrown object" do
          expect do
            :it.must_throw(:ball, :gently) { throw :ball, :gently }
          end.to throw_symbol(:ball, :gently)
          should_not notify
        end
        
        it "should notify if tag does not equal thrown tag" do
          expect do
            :it.must_throw(:pie, :gently) { throw :ball, :gently }
          end.to throw_symbol(:ball, :gently)
          should notify(":it.must_throw(:pie, :gently) {},"\
            " but threw :ball, :gently")
        end
        
        it "should notify if object does not equal thrown object" do
          expect do
            :it.must_throw(:ball, :fiercely) { throw :ball, :gently }
          end.to throw_symbol(:ball, :gently)
          should notify(":it.must_throw(:ball, :fiercely) {},"\
            " but threw :ball, :gently")
        end
        
        context "when checked object is nil" do
          it "should not notify if thrown object is nil" do
            expect do
              :it.must_throw(:ball, nil) { throw :ball, nil }
            end.to throw_symbol(:ball)
            should_not notify
          end
          
          it "should notify if thrown object is not nil" do
            expect do
              :it.must_throw(:ball, nil) { throw :ball, :gently }
            end.to throw_symbol(:ball)
            should notify(":it.must_throw(:ball, nil) {},"\
              " but threw :ball, :gently")
          end
        end
      end
    end
    
    describe "after disabled" do
      before_disable_after_enable
      
      it "should just yield" do
        did_yield = false
        :it.must_throw { did_yield = true }
        did_yield.should be true
      end
    end
    
    describe "safety" do
      it "should be unrelated to previous throw" do
        catch(:ball) { throw :ball }
        :it.must_throw {}
        should notify(":it.must_throw {}, but did not throw")
      end
      
      it "should ignore nested catches" do
        :it.must_throw do
          catch(:money) { throw :money }
        end
        should notify(":it.must_throw {}, but did not throw")
      end
      
      it "should allow for deeply nested #must_throw" do
        note = nil
        outer_note = nil
        expect do
          :it.must_throw do
            begin
              :it.must_throw(:party) do
                begin
                  :it.must_throw(:ball, :fiercely) do
                    throw :ball, :gently
                  end
                ensure
                  note = $note
                  $note = nil
                end
              end
            ensure
              outer_note = $note
              $note = nil
            end
          end
        end.to throw_symbol(:ball)
        note.message.should == ":it.must_throw(:ball, :fiercely) {},"\
          " but threw :ball, :gently"
        outer_note.message.should == ":it.must_throw(:party) {},"\
          " but threw :ball, :gently"
        should_not notify
      end
      
      it "should ignore caught nested #must_throw" do
        note = nil
        :it.must_throw do
          note = must_check do
            catch(:money) do
              :it.must_throw(:party) { throw :money }
            end
          end
        end
        note.message.should == ":it.must_throw(:party) {}, but threw :money"
        should notify(":it.must_throw {}, but did not throw")
      end
      
      it "should be error safe" do
        :it.must_throw do
          begin
            throw :uncaught
          rescue NameError, ArgumentError
          end
        end
        should notify(":it.must_throw {}, but did not throw")
      end
      
      if RUBY_VERSION > "1.9"
        it "should be fiber safe" do
          got_to_end = false
          fiber = Fiber.new do
            note = must_check do
              catch :ball do
                :it.must_throw(:party) do
                  begin
                    throw :ball
                  ensure
                    Fiber.yield
                  end
                end
              end
            end
            note.message.should == ":it.must_throw(:party) {},"\
              " but threw :ball"
            got_to_end = true
          end
          
          :it.must_throw do
            fiber.resume
          end
          fiber.resume
          
          got_to_end.should be true
          should notify(":it.must_throw {}, but did not throw")
        end
      end
    end
  end
  
  describe '#must_not_throw' do
    let(:the_method_name) { :must_not_throw }
    it_should_behave_like "*_throw in case of bad arguments"
    
    context "when block returns normally" do
      it "should not notify and should return the result" do
        :it.must_not_throw{:result}.should == :result
        should_not notify
      end
    end
    
    context "when block raises exception" do
      it "should not notify and should reraise" do
        expect do
          :it.must_not_throw { throw :uncaught }
        end.to raise_error(/uncaught throw/)
        should_not notify
      end
    end
    
    context "when block throws" do
      context "when called with no arguments" do
        it "should notify" do
          expect do
            :it.must_not_throw { throw :ball }
          end.to throw_symbol(:ball)
          should notify(":it.must_not_throw {}, but threw :ball")
        end
      end
      
      context "when called with tag" do
        it "should notify if tag equals thrown tag" do
          expect do
            :it.must_not_throw(:ball) { throw :ball }
          end.to throw_symbol(:ball)
          should notify(":it.must_not_throw(:ball) {}, but threw :ball")
        end
        
        it "should not notify if tag does not equal thrown tag" do
          expect do
            :it.must_not_throw(:pie) { throw :ball }
          end.to throw_symbol(:ball)
          should_not notify
        end
        
        context "when checked against object" do
          it "should not notify" do
            expect do
              :it.must_not_throw(:ball, :fiercely) { throw :ball }
            end.to throw_symbol(:ball)
            should_not notify(":it.must_not_throw(:ball, :fiercely) {},"\
              " but threw :ball")
          end
          
          it "should not notify even if checked object is nil" do
            expect do
              :it.must_not_throw(:ball, nil) { throw :ball }
            end.to throw_symbol(:ball)
            should_not notify
          end
        end
      end
            
      context "when called with tag and object" do
        it "should notify if tag equals thrown tag and"\
            " object equals thrown object" do
          expect do
            :it.must_not_throw(:ball, :gently) { throw :ball, :gently }
          end.to throw_symbol(:ball, :gently)
          should notify(":it.must_not_throw(:ball, :gently) {},"\
            " but threw :ball, :gently")
        end
        
        it "should not notify if tag does not equal thrown tag" do
          expect do
            :it.must_not_throw(:pie, :gently) { throw :ball, :gently }
          end.to throw_symbol(:ball, :gently)
          should_not notify
        end
        
        it "should not notify if object does not equal thrown object" do
          expect do
            :it.must_not_throw(:ball, :fiercely) { throw :ball, :gently }
          end.to throw_symbol(:ball, :gently)
          should_not notify
        end
        
        context "when checked object is nil" do
          it "should notify if thrown object is nil" do
            expect do
              :it.must_not_throw(:ball, nil) { throw :ball, nil }
            end.to throw_symbol(:ball)
            should notify(":it.must_not_throw(:ball, nil) {},"\
              " but threw :ball, nil")
          end
          
          it "should not notify if thrown object is not nil" do
            expect do
              :it.must_not_throw(:ball, nil) { throw :ball, :gently }
            end.to throw_symbol(:ball)
            should_not notify
          end
        end
      end
    end
    
    describe "safety" do
      it "should safely interact with #must_throw" do
        note = nil
        outer_note = nil
        expect do
          :it.must_not_throw do
            begin
              :it.must_throw(:ball) do
                begin
                  :it.must_not_throw(:ball, :gently) do
                    throw :ball, :gently
                  end
                ensure
                  note = $note
                  $note = nil
                end
              end
            ensure
              outer_note = $note
              $note = nil
            end
          end
        end.to throw_symbol(:ball)
        note.message.should == ":it.must_not_throw(:ball, :gently) {},"\
          " but threw :ball, :gently"
        outer_note.should == nil
        should notify(":it.must_not_throw {}, but threw :ball, :gently")
      end
    end
  end
end