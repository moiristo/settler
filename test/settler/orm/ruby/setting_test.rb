require 'test_helper'

module Settler
  module ORM
    module Ruby
      class SettingTest < MINITEST_CLASS

        def setup
          Settler.reset!
          Settler.orm = :ruby
          Settler.source = File.expand_path(File.dirname(__FILE__) + '/../../../files/settler.yml')
          Settler.namespace = 'settings'
          Settler.load!
        end

        def test_should_load_settings
          assert_equal ["bool_value", "custom_value", "datetime_value", "float_value", "google_analytics_key", "integer_value", "password_value", "search_algorithm"], Settler.settings(:order => :key)
        end

        def test_should_return_setting_label
          assert_equal 'Default search engine', Settler.search_algorithm.to_label
        end

        def test_should_find_setting_value
          assert_equal 'ferret', Settler[:search_algorithm]
          assert_equal 'ferret', Settler.search_algorithm.value
        end

        def test_should_get_validations_for_setting
          assert Settler.validations_for(:google_analytics_key).keys.include?('presence')
          assert_equal({"inclusion"=>["ferret", "sphinx"]}, Settler.validations_for(:search_algorithm))
        end

        def test_should_typecast
          require 'custom_typecaster'
          assert_equal 3, Settler.integer_value.value
          assert_equal 0.25, Settler.float_value.value
          assert_equal true, Settler.bool_value.value
          assert_equal DateTime.civil(2012, 01, 15), Settler.datetime_value.value
          assert_equal 'custom value', Settler.custom_value.value
        end

        def test_boolean_typecaster
          bool_setting = Settler.bool_value
          assert_equal true, bool_setting.value
        end

        def test_should_return_type
          assert Settler.integer_value.type.integer?
          assert Settler.float_value.type.float?
          assert Settler.bool_value.type.boolean?
          assert Settler.datetime_value.type.datetime?
          assert Settler.custom_value.type.string?
          assert_equal 'string', Settler.search_algorithm.type
        end

      end
    end
  end
end