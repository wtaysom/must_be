require 'lib/must_be'

MustBe.notifier = lambda do |note|
  $note = note
  false
end

def check_note(message)
  unless message == $note.message
    puts "expected: #{message}"
    puts "   found: #{$note.message}"
    raise "mismatch"
  end
end

example_text = IO.read(File.dirname(__FILE__)+"/example.rb")
example_text.gsub!(/^#=> (.*)$/, 'check_note(%{\1})')
eval example_text