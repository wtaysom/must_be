module MustBe
  VERSION = '0.0.4'

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
    attr_accessor :receiver, :assertion, :args, :block, :additional_message
    
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
      if @assertion
        "#{receiver.inspect}.#{assertion}#{format_args_and_block}"\
          "#{additional_message}"
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
        args_format = "(#{args.map(&:inspect).join(", ")})"
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
  
  def must_check
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
      must_notify(self, __method__, cases)
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

  def self.check_pair_against_hash_cases(key, value, cases)
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
  
  def self.must_check_pair_against_hash_cases(container, key, value, cases)
    unless MustBe.check_pair_against_hash_cases(key, value, cases)
      must_notify("pair #{{key => value}.inspect} does not match"\
        " #{cases.inspect} in #{container.inspect}")
    end
  end
  
  def self.must_check_item_against_cases(container, item, cases)
    note = item.must_check do
      item.must_be(*cases)
    end
    if note
      note.additional_message += " in container #{container.inspect}"
      must_notify(note)
    end
  end

  def must_only_contain(*cases)
    advice = MustOnlyEverContain.registered_class(self)    
    if advice and advice.respond_to? :must_only_contain_check
      advice.must_only_contain_check(self, cases)
    elsif respond_to? :each_pair
      each_pair do |key, value|
        MustBe.must_check_pair_against_hash_cases(self, key, value, cases)
      end
    else
      each do |item|
        MustBe.must_check_item_against_cases(self, item, cases)
      end
    end
    self
  end
  
  module MustOnlyEverContain
    REGISTERED_CLASSES = {}
    
    module Base
      attr_accessor :must_only_ever_contain_cases
      
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

      def must_only_ever_contain_cases=(cases)
        cases = [cases] unless cases.is_a? Array
        @must_only_ever_contain_cases = cases
        must_only_contain(*cases)
      end
      
    protected
      def must_check(item)
        MustBe.must_check_item_against_cases(self, item, 
          must_only_ever_contain_cases)
      end
      
      def must_check_pair(key, value)
        MustBe.must_check_pair_against_hash_cases(self, key, value,
          must_only_ever_contain_cases)
      end
      
      def must_check_contents(items = self)
        items.must_only_contain(*must_only_ever_contain_cases)
      end
    end
    
    ##
    # Creates a module from `body' which includes MustOnlyEverContain::Base.
    # The module will be mixed into an objects of type `klass' when 
    # `must_only_ever_contain' is called.  The module should override methods of
    # `klass' which modify the contents of the object.
    # If the module has a class method named `must_only_contain_check',
    # then this method is used by `MustBe#must_only_contain(object, cases)'
    # to check the contents of `object' against `cases'.  
    # `must_only_contain_check' should call `MustBe#must_notify' for any 
    # contents which do not match `cases'.
    #
    def self.register(klass, &body)
      unless klass.is_a? Class
        raise ArgumentError, "invalid value for Class: #{klass.inspect}"
      end
      if REGISTERED_CLASSES[klass]
        raise ArgumentError, "handler for #{klass} previously provided"
      end
      
      REGISTERED_CLASSES[klass] = mod = Module.new
      mod.class_eval do
        include Base
      end
      mod.class_eval &body
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
        must_check(obj)
        super
      end
      
      def []=(*args)
        if args.size == 3 or args[0].is_a? Range
          value = args[-1]
          if value.nil?
            # No check needed.
          elsif value.is_a? Array
            value.map {|v| must_check(v) }
          else
            must_check(value)
          end
        else
          must_check(args[1])
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
          must_check(args[0])
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
  
  def must_only_ever_contain(*cases)
    unless singleton_methods.empty?
      raise ArgumentError, "must_only_ever_contain adds singleton methods but"\
        " receiver #{self.inspect} already"\
        " has singleton methods #{singleton_methods.inspect}"
    end
    
    advice = MustOnlyEverContain.registered_class(self)
    if advice
      extend advice
      self.must_only_ever_contain_cases = cases
    else
      raise TypeError,
        "No MustOnlyEverContain.registered_class for #{self.class}"
    end
    self
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