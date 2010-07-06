module MustBe
  VERSION = '0.0.1'
  
  class <<self
    attr_accessor :notifier # should respond_to? :call with Note argument.
    
### Enable ###
        
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
    
    def enable?
      @disabled_methods.nil?
    end
  end
  
  self.notifier = RaiseNotifier = lambda {|note| true }
  
  def must_just_return(*args)
    self
  end
  
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
    if $must_check__is_checking
      $must_check__found = note
    else
      raise note if MustBe.notifier.call(note)
    end
    note
  end
  
  def must_check
    #! use thread-local variables
    was_checking = $must_check__is_checking
    $must_check__is_checking = true
    
    already_found = $must_check__found
    $must_check__found = nil
    
    yield(self)
    
    $must_check__found
  ensure
    $must_check__is_checking = was_checking
    $must_check__found = already_found
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

  def must_only_contain(*cases)
    if respond_to? :each_pair
      each_pair do |key, value|
        unless MustBe.check_pair_against_hash_cases(key, value, cases)
          #! better message
          must_notify("pair #{{key => value}.inspect} does not match"\
            " #{cases.inspect} in #{inspect}")
        end
      end
    else
      each do |item|
        #!! better message -- use `must_check' then
        # may want to customize Note to make it easier to build that custom
        # message
        item.must_be(*cases)
      end
    end
    self
  end
  
  #! other modules, rename, etc
  module MustOnlyEverContain
    REGISTERED_CLASSES = {}
    
    module Base
      attr_accessor :must_only_ever_contain_cases

      def must_only_ever_contain_cases=(cases)
        cases = [cases] unless cases.is_a? Array
        @must_only_ever_contain_cases = cases
        must_only_contain(*cases)
      end
      
    protected
      def must_check(item)
        #!! better message -- see must_only_contain
        item.must_be(*must_only_ever_contain_cases)
      end
    
      def must_check_pair(key, value)
        unless MustBe.check_pair_against_hash_cases(key, value,
            must_only_ever_contain_cases)
          #! better message
          must_notify("pair #{{key => value}.inspect} does not match"\
            " #{must_only_ever_contain_cases.inspect} in #{inspect}")
        end
      end
      
      def must_check_contents
        #! better message
        must_only_contain(*must_only_ever_contain_cases)
      end
      
      #!! a method for checking each -- relates to must_only_contain
    end
    
    #!! spec error pathways
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
    
    register Hash do
      def []=(key, value)
        must_check_pair(key, value)
        super
      end
      
      #!! spec all of the methods
      
      def store(key, value)
        must_check_pair(key, value)
        super
      end
      
      #!!! factor out must_check_contents_after :method, :method, :method
      
      def replace(other_hash)
        #! better message
        super
      ensure
        must_check_contents
      end
      
      def merge!(other_hash)
        super
      ensure
        must_check_contents
      end
      
      def update(other_hash)
        super
      ensure
        must_check_contents
      end
    end
  end
  
  #! should raise when there are already singleton methods defined on self
  #! spec that the installation depends on the class
  #! be able to register new classes (e.g. Set)
  def must_only_ever_contain(*cases)
    advice = MustOnlyEverContain::REGISTERED_CLASSES[self.class]
    if advice
      extend advice
      self.must_only_ever_contain_cases = cases
    elsif instance_of? Array
      #!! array case: lots of methods to override to be useful
      raise "Array receiver unimplemented"
    else
      #! complain
      raise "decide on the right error to raise: TypeError?"
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

### Automatically Inclue in Object ###

unless ENV["MUST_BE__SHOULD_NOT_AUTOMATICALLY_BE_INCLUDED_IN_OBJECT"]
  class Object
    include MustBe
  end
end