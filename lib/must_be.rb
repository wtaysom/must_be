require 'forwardable'

module MustBe
  VERSION = '0.0.4'

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
        line =~ %r{lib/must_be\.rb:}
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

### Basic Assertions ###
  
  def self.match_any_case?(v, cases)
    cases = [cases] unless cases.is_a? Array
    cases.any? {|c| c === v }
  end
  
  def must_be(*cases)
    unless cases.empty? ? self : MustBe.match_any_case?(self, cases)
      must_notify(self, __method__, cases, nil, ", but is #{self.class}")
    end
    self
  end

  def must_not_be(*cases)
    if cases.empty? ? self : MustBe.match_any_case?(self, cases)
      must_notify(self, __method__, cases, nil, ", but is #{self.class}")
    end
    self 
  end
  
  def must_be_in(collection)
    unless collection.include? self
      must_notify(self, __method__, [collection])
    end
    self
  end
  
  def must_not_be_in(collection)
    if collection.include? self
      must_notify(self, __method__, [collection])
    end
    self
  end
  
  def must_be_nil
    must_notify(self, __method__) unless nil?
    self
  end
  
  def must_not_be_nil
    must_notify(self, __method__) if nil?
    self
  end
  
  def must_be_true
    must_notify(self, __method__) unless self == true
    self
  end
  
  def must_be_false
    must_notify(self, __method__) unless self == false
    self
  end
  
  def must_be_boolean
    unless self == true or self == false
      must_notify(self, __method__)
    end
    self
  end
  
  def must_be_close(expected, delta = 0.1)
    unless (self - expected).abs < delta
      must_notify(self, __method__, [expected, delta])
    end
    self
  end
  
  def must_not_be_close(expected, delta = 0.1)
    if (self - expected).abs < delta
      must_notify(self, __method__, [expected, delta])
    end
    self
  end
  
### must and must_not ###
  
  class Proxy
    mandatory_methods = [:__id__, :object_id, :__send__]
    
    if RUBY_VERSION < "1.9"
      mandatory_methods.map! &:to_s
    end
    
    (instance_methods - mandatory_methods).each do |method|
      undef_method(method)
    end
    
    def initialize(delegate, assertion = :must)
      unless assertion == :must or assertion == :must_not
        raise ArgumentError,
          "assertion (#{assertion.inspect}) must be :must or :must_not"
      end
      @delegate = delegate
      @assertion = assertion
    end
    
    def method_missing(symbol, *args, &block)
      result = @delegate.send(symbol, *args, &block)
      assertion = result ? true : false
      unless assertion == (@assertion == :must)
        @delegate.must_notify(@delegate, "#{@assertion}.#{symbol}", args, 
          block)
      end
      result
    end
  end
  
  def must(message = nil, &block)
    if block_given?
      unless yield(self, message)
        if message
          must_notify(message)
        else
          must_notify(self, __method__, nil, block)
        end
      end
      self
    else
      Proxy.new(self, :must)
    end
  end
  
  def must_not(message = nil, &block)
    if block_given?
      if yield(self, message)
        if message
          must_notify(message)
        else
          must_notify(self, __method__, nil, block)
        end
      end
      self
    else
      Proxy.new(self, :must_not)
    end
  end

### Containers ###

  class ContainerNote < Note
    extend Forwardable
    
    attr_accessor :original_note, :container
    
    def_delegators :@original_note,
      :receiver, :receiver=,
      :assertion, :assertion=,
      :args, :args=,
      :block, :block=,
      :additional_message, :additional_message=,
      :prefix, :prefix=
    
    def initialize(original_note, container = nil)
      @original_note = original_note
      @container = container
    end
    
    def to_s
      if assertion
        super+" in container #{MustBe.short_inspect(container)}"
      else
        super
      end
    end
    
    alias regular_backtrace backtrace
    
    def backtrace
      return unless regular_backtrace
      
      if container.respond_to?(:must_only_ever_contain_backtrace) and 
          container.must_only_ever_contain_backtrace
        regular_backtrace+["=== caused by container ==="]+
          container.must_only_ever_contain_backtrace
      else
        regular_backtrace
      end
    end
  end
  
  class PairNote < ContainerNote
    attr_accessor :key, :value, :cases, :negate
    
    def initialize(key, value, cases, container, negate)
      super(Note.new(""), container)
      @key = key
      @value = value
      @cases = cases
      @negate = negate
    end
    
    def to_s
      match = negate ? "matches" : "does not match"
      "#{prefix}pair {#{MustBe.short_inspect(key)}=>"\
        "#{MustBe.short_inspect(value)}} #{match}"\
        " #{MustBe.short_inspect(cases)} in"\
        " container #{MustBe.short_inspect(container)}"
    end
  end

  def self.check_pair_against_hash_cases(key, value, cases, negate = false)
    if negate
      if cases.empty?
        !key and !value
      else        
        cases.all? do |c|
          c.all? do |k, v|
            not (match_any_case?(key, k) and match_any_case?(value, v))
          end
        end
      end
    else
      if cases.empty?
        key and value
      else
        cases.any? do |c|
          c.any? do |k, v|
            match_any_case?(key, k) and match_any_case?(value, v)
          end
        end
      end
    end
  end
  
  def self.must_check_item_against_cases(container, item, cases, negate = false)
    item.must_check(lambda do
      if negate
        item.must_not_be(*cases)
      else
        item.must_be(*cases)
      end
    end) do |note|
      note = ContainerNote.new(note, container)
      block_given? ? yield(note) : note
    end
  end

  def self.must_check_pair_against_hash_cases(container, key, value, cases,
      negate = false)
    unless MustBe.check_pair_against_hash_cases(key, value, cases, negate)
      note = PairNote.new(key, value, cases, container, negate)
      must_notify(block_given? ? yield(note) : note)
    end
  end
  
  def self.must_only_contain(container, cases, negate = false)
    prefix = negate ? "must_not_contain: " : "must_only_contain: "
    
    advice = MustOnlyEverContain.registered_class(container)    
    if advice and advice.respond_to? :must_only_contain_check
      advice.must_only_contain_check(container, cases, negate)
    elsif container.respond_to? :each_pair
      container.each_pair do |key, value|
        MustBe.must_check_pair_against_hash_cases(container, key, value,
            cases, negate) do |note|
          note.prefix = prefix
          note
        end
      end
    else
      container.each do |item|
        MustBe.must_check_item_against_cases(container, item, cases,
            negate) do |note|
          note.prefix = prefix
          note
        end
      end
    end
    container  
  end

  def must_only_contain(*cases)
    MustBe.must_only_contain(self, cases)
  end
  
  def must_not_contain(*cases)
    MustBe.must_only_contain(self, cases, true)
  end
  
  module MustOnlyEverContain
    REGISTERED_CLASSES = {}
    
    module Base
      attr_accessor :must_only_ever_contain_cases, 
        :must_only_ever_contain_backtrace, :must_only_ever_contain_negate
      
      module ClassMethods 
        def must_check_contents_after(*methods)
          methods.each do |method|
            define_method(method) do |*args, &block|
              begin
                super(*args, &block)
              ensure
                must_check_contents
              end
            end
          end
        end
      end
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      def must_only_ever_contain_prefix
        must_only_ever_contain_negate ? "must_never_ever_contain: " : 
          "must_only_ever_contain: "
      end

      def must_only_ever_contain_cases=(cases)
        cases = [cases] unless cases.is_a? Array
        @must_only_ever_contain_cases = cases
        
        must_check(lambda { must_check_contents }) do |note|
          note.prefix = must_only_ever_contain_prefix
          note
        end     
      end
      
    protected
    
      def must_check_item(item)
        MustBe.must_check_item_against_cases(self, item, 
          must_only_ever_contain_cases, must_only_ever_contain_negate)
      end
      
      def must_check_pair(key, value)
        MustBe.must_check_pair_against_hash_cases(self, key, value, 
          must_only_ever_contain_cases, must_only_ever_contain_negate)
      end
      
      def must_check_contents(items = self)
        MustBe.must_only_contain(items, must_only_ever_contain_cases,
          must_only_ever_contain_negate)
      end
    end
    
  public
    
    ##
    # Creates a module from `body' which includes MustOnlyEverContain::Base.
    # The module will be mixed into an objects of type `klass' when 
    # `must_only_ever_contain' is called.  The module should override methods of
    # `klass' which modify the contents of the object.
    # If the module has a class method
    # `must_only_contain_check(object, cases, negate = false)',
    # then this method is used by `MustBe.must_only_contain'
    # to check the contents of `object' against `cases'.
    # `must_only_contain_check' should call `MustBe#must_notify' for any 
    # contents which do not match `cases'.  (Or if `negate' is true, then
    # `MustBe#must_notify' should be called for any contents that do match
    # `cases'.)
    #
    def self.register(klass, &body)
      unless klass.is_a? Class
        raise ArgumentError, "invalid value for Class: #{klass.inspect}"
      end
      if REGISTERED_CLASSES[klass]
        raise ArgumentError, "handler for #{klass} previously provided"
      end
      
      REGISTERED_CLASSES[klass] = mod = Module.new
      mod.send(:include, Base)
      mod.class_eval &body
      
      mutator_advice = Module.new
      mod.instance_methods(false).each do |method_name|
        mutator_advice.send(:define_method, method_name) do |*args, &block|
          must_check(lambda { super(*args, &block) }) do |note|
            note.prefix = nil
            call_s = Note.new(self.class, method_name, args, block).message
            call_s.sub!(".", "#")
            note.prefix = "#{must_only_ever_contain_prefix}#{call_s}\n"
            note
          end
        end
      end
      mod.const_set(:MutatorAdvice, mutator_advice)
      mod.instance_eval do
        def extended(base)
          base.extend(const_get(:MutatorAdvice))
        end
      end
      
      mod
    end
    
    def self.registered_class(object)
      REGISTERED_CLASSES[object.class]
    end
    
    def self.unregister(klass)
      REGISTERED_CLASSES.delete(klass)
    end
    
    register Array do
      must_check_contents_after :collect!, :map!, :flatten!
      
      def <<(obj)
        must_check_item(obj)
        super
      end
      
      def []=(*args)
        if args.size == 3 or args[0].is_a? Range
          value = args[-1]
          if value.nil?
            # No check needed.
          elsif value.is_a? Array
            value.map {|v| must_check_item(v) }
          else
            must_check_item(value)
          end
        else
          must_check_item(args[1])
        end
        super
      end
      
      def concat(other_array)
        must_check_contents(other_array)
        super
      end
      
      def fill(*args)
        if block_given?
          begin
            super
          ensure
            must_check_contents
          end
        else
          must_check_item(args[0])
          super
        end
      end
      
      def insert(index, *objs)
        must_check_contents(objs)
        super
      end
      
      def push(*objs)
        must_check_contents(objs)
        super
      end
      
      def replace(other_array)
        must_check_contents(other_array)
        super
      end
      
      def unshift(*objs)
        must_check_contents(objs)
        super
      end
    end
    
    register Hash do
      must_check_contents_after :replace, :merge!, :update
      
      def []=(key, value)
        must_check_pair(key, value)
        super
      end
            
      def store(key, value)
        must_check_pair(key, value)
        super
      end
    end
  end
  
  def self.must_only_ever_contain(container, cases, negate = false)
    unless container.singleton_methods.empty?
      method_name = "must_#{negate ? "never" : "only"}_ever_contain"
      raise ArgumentError, "#{method_name} adds singleton methods but"\
        " receiver #{MustBe.short_inspect(container)} already"\
        " has singleton methods #{container.singleton_methods.inspect}"
    end
    
    advice = MustOnlyEverContain.registered_class(container)
    if advice
      container.extend advice
      container.must_only_ever_contain_backtrace = caller
      container.must_only_ever_contain_negate = negate
      container.must_only_ever_contain_cases = cases
    else
      raise TypeError,
        "No MustOnlyEverContain.registered_class for #{container.class}"
    end
    container
  end
  
  def must_only_ever_contain(*cases)
    MustBe.must_only_ever_contain(self, cases)
  end
  
  def must_never_ever_contain(*cases)
    MustBe.must_only_ever_contain(self, cases, true)
  end
end

### Proc Case Equality Patch ###
#
# Semantics of case equality `===' for Proc changed between Ruby 1.8 (useless)
# and Ruby 1.9 (awesome).  So let's fix 'er up.
#
if RUBY_VERSION < "1.9"
  class Proc
    alias === call
  end
end

### Automatically Include in Object ###

unless ENV['MUST_BE__DO_NOT_AUTOMATICALLY_INCLUDE_IN_OBJECT']
  class Object
    include MustBe
  end
end