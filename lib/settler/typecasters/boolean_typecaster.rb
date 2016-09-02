module Settler
  module Typecasters
    # Casts a value to a boolean. '1', 't' or 'true' (case ignored) will evaluate to
    # true, otherwise the result will be false.
    class BooleanTypecaster < Settler::Typecaster
      def type; 'boolean' end

      def typecast(value)
        !(/^(1|t|true)$/i =~ value.to_s).nil?
      end
    end
  end
end