module MustBe
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