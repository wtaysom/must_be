require 'lib/must_be'

$expecting_note = false

class ExpectedNoteError < StandardError; end
class MismatchedNoteError < StandardError; end

MustBe.notifier = lambda do |note|
  unless $expecting_note
    raise ExpectedNoteError
  end
  $note = note
  false
end

def check_note(message)
  $expecting_note = true
  $note = nil
  yield
  unless $note and message === $note.message
    puts "expected: #{message.is_a?(Regexp) ? message.inspect : message}"
    if $note
      puts "   found: #{$note.message}"
    else
      puts "but did not notify"
    end
    raise MismatchedNoteError
  end
ensure
  $expecting_note = false
end

example_text = IO.read(File.dirname(__FILE__)+"/example.rb")
example_text.gsub!(/^(.*)\n#=> (.*)$/, "check_note(%{\\2}) {\n\\1}")
example_text.gsub!(/^(.*)\n#~> (.*)$/, "check_note(%r{\\2}) {\n\\1}")

begin
  eval example_text
  puts "Examples are okay."
rescue ExpectedNoteError => ex
  eval_frame = ex.backtrace.last
  eval_frame =~ /:(\d+)$/
  eval_line = $1.to_i
  offending_line = example_text.split($/)[eval_line - 1]
  puts "example.rb:#{eval_line}: expected note: #{offending_line}"
rescue MismatchedNoteError
end