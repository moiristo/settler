module Settler
  module Typecasters
    # Casts a value to a float
    class FloatTypecaster < Settler::Typecaster
      def type; 'float' end

      def typecast(value)
        value.to_f
      end
    end
  end
end