require 'singleton'

module Settler
  # The TypeClaster class maintains a list of typecasters and retrieves the appropriate typecaster
  # for a given data type.
  class Typecaster
    include Singleton

    # Returns the list of available typecasters
    def self.registered_typecasters
      @@registered_typecasters ||= [
        self.instance,
        Typecasters::IntegerTypecaster.instance,
        Typecasters::FloatTypecaster.instance,
        Typecasters::DatetimeTypecaster.instance,
        Typecasters::BooleanTypecaster.instance,
        Typecasters::PasswordTypecaster.instance
      ]
    end

    # Returns the first typecaster from the list of typecasters that is able to typecast the passed type.
    def self.typecaster_for(typecast)
      if typecast && typecaster = registered_typecasters.detect{|tc| tc.type == typecast }
        typecaster
      elsif typecast && typecasterClass = constantize(typecast)
        typecasterClass.instance
      else
        self.instance
      end
    end

    # Subclasses should implement this method and return the type of data it can typecast.
    def type; nil end

    # Subclasses should implement this method and return the typecasted value of the passed value.
    # By default, the untypecasted value will be returned.
    def typecast(value)
      value
    end

    alias :typecast_on_write :typecast

    def typecast_on_write?
      Settler.typecast_on_write
    end

  private

    # Taken from activesupport
    def self.constantize(camel_cased_word)
      begin
        names = camel_cased_word.split('::')

        # Trigger a built-in NameError exception including the ill-formed constant in the message.
        Object.const_get(camel_cased_word) if names.empty?

        # Remove the first blank element in case of '::ClassName' notation.
        names.shift if names.size > 1 && names.first.empty?

        names.inject(Object) do |constant, name|
          if constant == Object
            constant.const_get(name)
          else
            candidate = constant.const_get(name)
            next candidate if constant.const_defined?(name, false)
            next candidate unless Object.const_defined?(name)

            # Go down the ancestors to check if it is owned directly. The check
            # stops when we reach Object or the end of ancestors tree.
            constant = constant.ancestors.inject do |const, ancestor|
              break const    if ancestor == Object
              break ancestor if ancestor.const_defined?(name, false)
              const
            end

            # owner is in Object, so raise
            constant.const_get(name, false)
          end
        end
      rescue NameError
        nil
      end
    end

  end
end