require 'spec_helper'

# Since the notify matcher has lots of cases, we should spec out each
# possible combination to make sure it has the expected behavior.
#
# Patterns are built by choosing:
#   Whether there is a note:
#     :note
#     :no_note
#   Polarity of the expectation:
#     :should
#     :should_not
#   Message argument of notify matcher:
#     nil
#     'same'
#     'different'
#
describe "notify matcher" do
  include MustBeExampleHelper
  
  def self.it_should_follow_pattern(note, polarity, message, result)      
    context "when there is #{note == :note ? "a" : "no"} note" do
      message_arg = message ? %{("#{message}")} : ""
      call = "#{polarity} notify#{message_arg}"
      it "should #{result ? "fail" : "succeed"} if expecting #{call}" do
        pattern_notify = lambda do
          must_notify('same') if note == :note
          send(polarity, notify(message))
        end
      
        pattern_notify.send(result ? :should : :should_not, raise_error(
          Spec::Expectations::ExpectationNotMetError, result))
      end
    end
  end

  it_should_follow_pattern :note, :should, nil, nil
  it_should_follow_pattern :note, :should, 'same', nil
  it_should_follow_pattern :note, :should, 'different',
    'expected note with message: "different"' "\n"\
    '     got note with message: "same"'
  it_should_follow_pattern :note, :should_not, nil,
    'expected no note' "\n"\
    'got note with message: "same"'
  it_should_follow_pattern :note, :should_not, 'same',
    'did NOT expect note with message: "same"' "\n"\
    '           got note with message: "same"'
  it_should_follow_pattern :note, :should_not, 'different', nil

  it_should_follow_pattern :no_note, :should, nil,
    'expected a note'
  it_should_follow_pattern :no_note, :should, 'same',
    'expected a note with message: "same"'
  it_should_follow_pattern :no_note, :should, 'different',
    'expected a note with message: "different"'
  it_should_follow_pattern :no_note, :should_not, nil, nil
  it_should_follow_pattern :no_note, :should_not, 'same', nil
  it_should_follow_pattern :no_note, :should_not, 'different', nil
end