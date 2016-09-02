module Settler
  module Typecasters
    # Casts a value to a datetime
    class DatetimeTypecaster < Settler::Typecaster
      def type; 'datetime' end

      def typecast(value)
        ::DateTime.parse(value, false) unless value.to_s.strip.empty?
      end
    end
  end
end