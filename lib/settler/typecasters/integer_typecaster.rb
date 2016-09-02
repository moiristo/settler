module Settler
  module Typecasters
    # Casts a value to an integer
    class IntegerTypecaster < Settler::Typecaster
      def type; 'integer' end

      def typecast(value)
        value.to_i
      end
    end
  end
end