module Settler
  module ORM
    module Activerecord
      # The Setting class is an AR model that encapsulates a Settler setting. The key of the setting is the only required attribute.
      class Setting < ::ActiveRecord::Base
        include Settler::AbstractSetting

        self.table_name = 'settings'

        attr_readonly :key

        alias :read_setting_attribute :read_attribute
        alias :write_setting_attribute :write_attribute

        serialize :value

        validates :key, :presence => true
        validate  :setting_validations
        validate  :ensure_editable, :on => :update

        default_scope { where(['deleted = ? or deleted IS NULL', false]) }

        scope :editable, lambda{ where(:editable => true) }
        scope :deletable, lambda{ where(:deletable => true) }

        # Performs a soft delete of the setting if this setting is deletable. This ensures this setting is not recreated from the configuraiton file.
        # Returns false if the setting could not be destroyed.
        def destroy
          if deletable?
            self.deleted = true if Setting.where(:id => self).update_all(:deleted => true)
            deleted?
          else
            false
          end
        end

        # Overrides the delete methods to ensure the default scope is not passed in the query
        def delete *args;           Setting.unscoped{ super } end
        def self.delete_all *args;  Setting.unscoped{ super } end

        # Resets this setting to the default stored in the settler configuration
        def reset!
          defaults = Settler.config[self.key]
          self.label = defaults['label']
          self.value = defaults['value']
          self.editable = defaults['editable']
          self.deletable = defaults['deletable']
          self.deleted = false
          save(:validate => false)
        end

        # Deleted scope is specified as a method as it needs to be an exclusive scope
        def self.deleted
          unscoped { Setting.where(:deleted => true) }
        end

        def self.all_keys options = {}
          Setting.order(options[:order]).select(:key).map(&:key)
        end

        def self.build_settings! config
          Setting.unscoped do
            config.each do |key, attributes|
              if Setting.where(:key => key).none?
                setting = Setting.new
                setting.key       = key
                setting.label     = attributes['label']
                setting.value     = attributes['value']
                setting.editable  = attributes['editable']
                setting.deletable = attributes['deletable']
                setting.save

                p "[Settler] Validation failed for setting '#{setting.key}': #{setting.errors.full_messages.to_sentence}" if !setting.valid?
              end
            end
          end
        end

      private

        # Performs instance validations as defined in the settler configuration.
        def setting_validations
          if errors.empty?
            errors.add(:value, :blank) if validators['presence'] && ['1','true',true].include?(validators['presence']) && self.value.nil?
            errors.add(:value, :inclusion) if valid_values && !valid_values.include?(self.value)
            errors.add(:value, :invalid) if validators['format'] && !(Regexp.new(validators['format']) =~ self.value)
          end
        end

        # Ensures uneditable settings cannot be updated.
        def ensure_editable
          errors.add(:base, I18n.t('settler.errors.editable', :default => 'Setting cannot be changed')) if changed? && !editable?
        end
      end
    end
  end
end