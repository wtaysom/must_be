require 'lib/must_be'

$expecting_note = false

class UnexpectedNoteError < StandardError; end
class MismatchedNoteError < StandardError; end

MustBe.notifier = lambda do |note|
  $note = note
  unless $expecting_note
    raise UnexpectedNoteError
  end
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
rescue UnexpectedNoteError => ex
  eval_frame = ex.backtrace.last
  eval_frame =~ /:(\d+)$/
  eval_line = $1.to_i
  puts "example.rb:#{eval_line}: unexpected note: #{$note}"
rescue MismatchedNoteError
end