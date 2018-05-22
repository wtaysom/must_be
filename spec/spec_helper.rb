### MUST_BE__DO_NOT_AUTOMATICALLY_INCLUDE_IN_OBJECT ###
#
# Hard to describe within normal RSpec control flow.  Instead we raise a
# RuntimeError if MUST_BE__DO_NOT_AUTOMATICALLY_INCLUDE_IN_OBJECT doesn't
# behave as expected.
#

ENV['MUST_BE__NOTIFIER'] = nil # to make `rake spec` work.
ENV['MUST_BE__DO_NOT_AUTOMATICALLY_INCLUDE_IN_OBJECT'] = "" # any string.

require './lib/must_be'

if Object.include? MustBe
  raise "MustBe should not be automatically included in Object."
end

def expect_error(error_type)
  begin
    raised_error = false
    yield
  rescue error_type
    raised_error = true
  end
  raise "expected #{error_type}" unless raised_error
end

# Show that MustBe does not need to be included in Object to be useful.
def example_of_must_be_inclusion
  example = Object.new
  example.extend(MustBe)
  example.must == example
  example.must_not_be_nil

  # must_only_contain and must_not_contain require contents to also include
  # MustBe.
  contents = Object.new

  container = [contents]
  container.extend(MustBe)

  expect_error(NoMethodError) do
    container.must_only_contain
  end

  contents.extend(MustBe)
  expect_error(MustBe::Note) do
    container.must_not_contain
  end
end
example_of_must_be_inclusion

class Object
  include MustBe
end

### MustBeExampleHelper ###

require 'rspec/its'

# Some old syntax.
RSpec.configure do |config|
  config.expect_with(:rspec){|c| c.syntax = [:should, :expect]}
end

# Some old semantics.
RSpec::Expectations.configuration.on_potential_false_positives = :nothing

module MustBeExampleHelper
  
  $default_must_be_notifier = MustBe.notifier
  
  def self.included(example_group)
    example_group.before do
      MustBe.notifier = lambda do |note|
        $note = note
        false
      end
    end
    
    example_group.after do
      $note = nil
    end

    class <<example_group
      
      ### Value Assertion ###
      
      def it_should_have_must_be_value_assertion(method, value, alt = 411)
        describe '##{method}' do
          it "should not notify if receiver is #{value.inspect}" do
            value.send(method).should == value
            should_not notify
          end

          it "should notify if receiver is not #{value.inspect}" do
            alt.send(method).should == alt
            should notify("#{alt.inspect}.#{method}")
          end
        end
      end

      def it_should_have_must_not_be_value_assertion(method, value, alt = 411)
        describe '##{method}' do
          it "should notify if receiver is #{value.inspect}" do
            value.send(method)
            should notify("#{value.inspect}.#{method}")
          end

          it "should not notify if receiver is not #{value.inspect}" do
            alt.send(method)
            should_not notify
          end
        end
      end
    
      ### Notify Example ###

      def notify_example(expression, message = nil)
        expression = expression.gsub(/\n\s*/, " ")
        if message.is_a? Module
          message = expression+", but matches #{message}"
        end
        example "#{expression} should #{message ? "" : "not "}notify" do
          eval(expression)
          if message == true
            should notify
          elsif message
            should notify(message)
          else
            should_not notify
          end
        end
      end
      
      ### Enable ###
      
      def before_disable_after_enable
        before do
          MustBe.disable
        end
        
        after do
          MustBe.enable
        end
      end
      
      def before_disable_and_reenable
        before do
         MustBe.disable
         MustBe.enable
        end
      end
    end
  end
  
  ### Notify Matcher ###
  
  RSpec::Matchers.define :notify do |*message|
    if (count = message.size) > 1
      raise ArgumentError, "wrong number of arguments (#{count} for 1)"
    end
    message = message[0]
    
    def does(message)
      @message = message
      true
    end
    
    def does_not(message)
      @message = message
      false
    end
        
    match do |given|
      if $note
        if message
          if message === $note.message
            does(
              "did NOT expect note with message: #{message.inspect}\n"\
              "           got note with message: #{$note.message.inspect}")
          else
            does_not(
              "expected note with message: #{message.inspect}\n"\
              "     got note with message: #{$note.message.inspect}")
          end
        else
          does(
            "expected no note\n"\
            "got note with message: #{$note.message.inspect}")
        end
      else
        does_not(if message
          "expected a note with message: #{message.inspect}"
        else
          "expected a note"
        end)
      end
    end
    
    failure_message do |given|
      @message
    end
    
    failure_message_when_negated do |given|
      @message
    end
  end
end