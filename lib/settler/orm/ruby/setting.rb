module Settler
  module ORM
    module Ruby
      class Setting
        include Settler::AbstractSetting

        attr_accessor :key, :label

        def initialize key, label, value
          self.key    = key
          self.label  = label
          self.value  = value
        end

        def self.build_settings! config
          config.map do |key, attributes|
            if all.none?{|setting| setting.key == key }
              @@settings << self.new(key, attributes['label'], attributes['value'])
            end
          end
        end

        def self.all
          @@settings ||= []
        end

        def self.all_keys options = {}
          settings = all
          settings = settings.sort_by(&options[:order]) if options[:order]
          settings.map(&:key)
        end

        def self.find_by_key key
          all.detect{|setting| setting.key == key.to_s }
        end

        def read_setting_attribute attribute
          instance_variable_get("@#{attribute}") if %w(key label value).include?(attribute.to_s)
        end

        def write_setting_attribute attribute, value
          instance_variable_set("@#{attribute}", value) if %w(key label value).include?(attribute.to_s)
        end

        private :key=, :label=, :value=, :write_setting_attribute

      end
    end
  end
end