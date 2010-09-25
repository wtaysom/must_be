require './lib/must_be'

$expecting_note = false

class UnexpectedNoteError < StandardError; end
class MismatchedNoteError < StandardError; end

MustBe.notifier = lambda do |note|
  unless $expecting_note
    $note = note
    raise UnexpectedNoteError
  end
  true
end

def log(message, details)
  puts "expected: #{message.is_a?(Regexp) ? message.inspect : message}"
  puts details
end

def check_note(message)
  $expecting_note = true
  yield
  log(message, "but did not notify")
rescue Note => note
  unless message === note.message
    log(message, "   found: #{note.message}")
    raise MismatchedNoteError
  end
ensure
  $expecting_note = false
end

example_text = IO.read(File.dirname(__FILE__)+"/examples.rb")
example_text.gsub!(/^(.*)\n#=> (.*)$/, "check_note(%{\\2}) {\n\\1}")
example_text.gsub!(/^(.*)\n#~> (.*)$/, "check_note(%r{\\2}) {\n\\1}")

begin
  eval(example_text)
  puts "Examples are okay."
rescue UnexpectedNoteError => ex
  eval_frame = ex.backtrace.last
  eval_frame =~ /:(\d+)$/
  eval_line = $1.to_i
  puts "example.rb:#{eval_line}: unexpected note: #=> #{$note}"
rescue MismatchedNoteError
end