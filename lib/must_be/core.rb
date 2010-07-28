module MustBe
  
  ### Short Inspect ###
  
  SHORT_INSPECT_CUTOFF_LENGTH = 200
  SHORT_INSPECT_WORD_BREAK_LENGTH = 20
  SHORT_INSPECT_ELLIPSES = "..."

  def self.short_inspect(obj)
    s = obj.inspect
    if s.bytesize > SHORT_INSPECT_CUTOFF_LENGTH
      real_cutoff = SHORT_INSPECT_CUTOFF_LENGTH - SHORT_INSPECT_ELLIPSES.length
      left_side = (real_cutoff + 1) / 2
      right_side = -(real_cutoff / 2)
      
      left_start = left_side - SHORT_INSPECT_WORD_BREAK_LENGTH
      left_word_break_area = s[left_start, SHORT_INSPECT_WORD_BREAK_LENGTH]
      left_word_break = left_word_break_area.rindex(/\b\s/)
      start = left_word_break ? left_start + left_word_break + 1 : left_side
      
      right_start = right_side
      right_word_break_area = s[right_start, SHORT_INSPECT_WORD_BREAK_LENGTH]
      right_word_break = right_word_break_area.index(/\s\b/)
      stop = right_word_break ? right_start + right_word_break : right_side
      
      s[start...stop] = SHORT_INSPECT_ELLIPSES
    end
    s
  end
  
  ### Enable ###
  
  class <<self
    def disable
      @disabled_methods = instance_methods.map do |method_name|
        method = instance_method(method_name)
        alias_method method_name, :must_just_return
        [method_name, method]
      end
    end
    
    def enable
      @disabled_methods.each do |method_record|
        define_method *method_record
      end
      @disabled_methods = nil
    end
    
    def enabled?
      @disabled_methods.nil?
    end
  end
  
  def must_just_return(*args)
    self
  end
  
  ### Notifiers ###
  
  NOTIFIERS = {}
  
  class <<self
    attr_accessor :notifier # should respond_to? :call with Note argument.
    
    def def_notifier(constant_name, key = nil, &notifier)
      const_set(constant_name, notifier)
      NOTIFIERS[key] = constant_name if key
    end
    
    def set_notifier_from_env(key = ENV['MUST_BE__NOTIFIER'])
      key = key.to_sym
      
      if key == :disable
        disable
        return
      end
      
      constant_name = NOTIFIERS[key]
      unless constant_name
        raise ArgumentError, "no MustBe::NOTIFIERS called #{key.inspect}"
      end
      self.notifier = const_get(constant_name)
    end
  end
  
  def_notifier(:RaiseNotifier, :raise) {|note| true }
  
  def_notifier(:LogNotifier, :log) do |note|
    begin
      raise note
    rescue Note
      puts [note.message, *note.backtrace].join("\n\t")
    end
    false
  end
  
  def_notifier(:DebugNotifier, :debug) do |note|
    $must_be__note = note
    puts note.message
    puts "Starting debugger ($must_be__note stores the note)..."
    require 'ruby-debug'
    debugger
    false
  end

  set_notifier_from_env(ENV['MUST_BE__NOTIFIER'] || :raise)
  
  ### Note ###
  
  class Note < StandardError
    attr_accessor :receiver, :assertion, :args, :block, :additional_message,
      :prefix
    
    def initialize(receiver, assertion = nil, args = nil, block = nil,
        additional_message = nil)
      if assertion
        @receiver = receiver
        @assertion = assertion
        @args = args
        @block = block
        @additional_message = additional_message
      else
        super(receiver)
      end
    end
    
    def to_s
      if assertion
        "#{prefix}#{MustBe.short_inspect(receiver)}."\
          "#{assertion}#{format_args_and_block}#{additional_message}"
      else
        super
      end
    end
        
    alias complete_backtrace backtrace
    
    def backtrace
      complete_backtrace and complete_backtrace.drop_while do |line|
        line =~ %r{lib/must_be.*\.rb:}
      end
    end
  
  private
    
    def format_args_and_block
      if args.nil? or args.empty?
        if block.nil?
          ""
        else
          " {}"
        end
      else
        args_format = "(#{args.map{|v| MustBe.short_inspect(v) }.join(", ")})"
        if block.nil?
          args_format
        else
          args_format+" {}"
        end
      end
    end
  end
  
  def must_notify(receiver = nil, assertion= nil, args = nil, block = nil,
      additional_message = nil)
    note = Note === receiver ? receiver :
      Note.new(receiver, assertion, args, block, additional_message)
    if Thread.current[:must_check__is_checking]
      Thread.current[:must_check__found_note] = note
    else
      raise note if MustBe.notifier.call(note)
    end
    note
  end
  
  def must_check(check_block = nil, &block)
    if check_block
      result = nil
      note = must_check do |obj|
        result = check_block.arity.zero? ? check_block[] : check_block[obj]
      end
      if note
        must_notify(block[note])
      end
      return result
    end
    
    begin
      was_checking = Thread.current[:must_check__is_checking]
      Thread.current[:must_check__is_checking] = true
    
      already_found = Thread.current[:must_check__found_note]
      Thread.current[:must_check__found_note] = nil
    
      yield(self)
    
      Thread.current[:must_check__found_note]
    ensure
      Thread.current[:must_check__is_checking] = was_checking
      Thread.current[:must_check__found_note] = already_found
    end
  end
end

### Automatically Include in Object ###

unless ENV['MUST_BE__DO_NOT_AUTOMATICALLY_INCLUDE_IN_OBJECT']
  class Object
    include MustBe
  end
end