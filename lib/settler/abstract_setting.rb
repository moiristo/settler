module Settler
  module AbstractSetting

    module Interface
      def self.build_settings! config;              raise NotImplementedError end
      def self.all;                                 raise NotImplementedError end
      def self.all_keys options = {};               raise NotImplementedError end
      def self.find_by_key key;                     raise NotImplementedError end
      def read_setting_attribute attribute;         raise NotImplementedError end
      def write_setting_attribute attribute, value; raise NotImplementedError end
    end

    include Interface

    # Returns the value, typecasted if a typecaster is available.
    def value
      typecast ? typecasted_value : read_setting_attribute(:value)
    end

    def value=(val)
      write_setting_attribute(:value, (typecaster && typecaster.typecast_on_write? ? typecaster.typecast_on_write(val) : val))
    end

    # Reads the raw, untypecasted value.
    def untypecasted_value
      read_setting_attribute(:value)
    end

    # Returns the typecasted value or the raw value if a typecaster could not be found.
    def typecasted_value
      typecaster ? typecaster.typecast(untypecasted_value) : untypecasted_value
    end

    # Finds the typecast for this key in the settler configuration.
    def typecast
      @typecast ||= Settler.typecast_for(key)
    end

    def type
      @type ||= Settler::StringInquirer.new(typecaster ? (typecaster.type || 'string') : 'string')
    end

    def to_label
      label.to_s.strip.empty? ? key : label
    end

    # Returns all valid values for this setting, which is based on the presence of an inclusion validator.
    # Will return nil if no valid values could be determined.
    def valid_values
      if validators['inclusion']
        return case
          when validators['inclusion'].is_a?(Array) then validators['inclusion']
          when validators['inclusion'].is_a?(String) then validators['inclusion'].to_s.split(',').map{|v| v.to_s.strip }
          else nil
        end
      end
      nil
    end

  private

    # Retrieves all validators defined for this setting.
    def validators
      @validators ||= Settler.validations_for(key)
    end

    # Retrieves the typecaster instance that will typecast the value of this setting.
    def typecaster
      @typecaster ||= Settler::Typecaster.typecaster_for(typecast)
    end

  end
end