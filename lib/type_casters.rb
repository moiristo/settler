require 'singleton'

# The TypeClaster class maintains a list of typecasters and retrieves the appropriate typecaster
# for a given data type.
class Typecaster
  include Singleton

  # Returns the list of available typecasters
  def self.registered_typecasters
    @@registered_typecasters ||= [self.instance, IntegerTypecaster.instance, FloatTypecaster.instance, BooleanTypecaster.instance]
  end
  
  # Returns the first typecaster from the list of typecasters that is able to typecast the passed type.
  def self.typecaster_for(typecast)
    typecaster = typecast.constantize.instance rescue nil
    typecaster.present? && typecaster.is_a?(Typecaster) ? typecaster : registered_typecasters.detect{|tc| tc.type == typecast } || self.new
  end
  
  # Subclasses should implement this method and return the type of data it can typecast.
  def type; nil end
  
  # Subclasses should implement this method and return the typecasted value of the passed value.
  # By default, the untypecasted value will be returned.
  def typecast(value)
    value
  end
end

# Casts a value to an integer
class IntegerTypecaster < Typecaster
  def type; 'integer' end
  
  def typecast(value)
    value.to_i
  end
end

# Casts a value to a float
class FloatTypecaster < Typecaster
  def type; 'float' end
  
  def typecast(value)
    value.to_f
  end
end

# Casts a value to a boolean. '1', 't' or 'true' (case ignored) will evaluate to 
# true, otherwise the result will be false.
class BooleanTypecaster < Typecaster
  def type; 'boolean' end
  
  def typecast(value)
    !(/^(1|t|true)$/i =~ value.to_s).nil?
  end
end