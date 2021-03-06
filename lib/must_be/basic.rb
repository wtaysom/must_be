module MustBe
  def self.match_any_case?(v, cases)
    cases = [cases] unless cases.is_a? Array
    cases.any? {|c| c === v }
  end
  
  def must_be(*cases)
    unless cases.empty? ? self : MustBe.match_any_case?(self, cases)
      must_notify(self, :must_be, cases, nil, ", but matches #{self.class}")
    end
    self
  end

  def must_not_be(*cases)
    if cases.empty? ? self : MustBe.match_any_case?(self, cases)
      must_notify(self, :must_not_be, cases, nil, ", but matches #{self.class}")
    end
    self
  end
  
private

  def must_be_a__body(modules, test_method, method)
    if modules.size.zero?
      raise ArgumentError, "wrong number of arguments (0 for 1)"
    end
    ms = modules.last.is_a?(Module) ? modules : modules[0..-2]
    if ms.size.zero?
      raise TypeError, "class or module required"
    end
    ms.each do |mod|
      raise TypeError, "class or module required" unless mod.is_a? Module
    end
        
    if ms.send(test_method) {|mod| is_a? mod }
      must_notify(self, method, modules, nil, ", but is a #{self.class}")
    end
    self
  end

public
  
  def must_be_a(*modules)
    must_be_a__body(modules, :none?, :must_be_a)
  end
  
  def must_not_be_a(*modules)
    must_be_a__body(modules, :any?, :must_not_be_a)
  end
  
  def must_be_in(*collection)
    cs = collection.size == 1 ? collection[0] : collection
    unless cs.include? self
      must_notify(self, :must_be_in, collection)
    end
    self
  end
  
  def must_not_be_in(*collection)
    cs = collection.size == 1 ? collection[0] : collection
    if cs.include? self
      must_notify(self, :must_not_be_in, collection)
    end
    self
  end
  
  def must_be_nil
    must_notify(self, :must_be_nil) unless nil?
    self
  end
  
  def must_not_be_nil
    must_notify(self, :must_not_be_nil) if nil?
    self
  end
  
  def must_be_true
    must_notify(self, :must_be_true) unless self == true
    self
  end
  
  def must_be_false
    must_notify(self, :must_be_false) unless self == false
    self
  end
  
  def must_be_boolean
    unless self == true or self == false
      must_notify(self, :must_be_boolean)
    end
    self
  end
  
  def must_be_close(expected, delta = 0.1)
    difference = (self - expected).abs
    unless difference < delta
      must_notify(self, :must_be_close, [expected, delta], nil,
        ", difference is #{difference}")
    end
    self
  end
  
  def must_not_be_close(expected, delta = 0.1)
    if (self - expected).abs < delta
      must_notify(self, :must_not_be_close, [expected, delta])
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