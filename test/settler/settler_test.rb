require 'test_helper'

class SettlerTest < MINITEST_CLASS

  def setup
    Settler.reset!
    Settler.orm = :activerecord
    Settler.setting_class.delete_all
    Settler.source = File.expand_path(File.dirname(__FILE__) + '/../files/settler.yml')
    Settler.namespace = 'settings'
    Settler.load!
  end

  def test_should_not_crash_if_config_missing
    Settler.source = File.dirname(__FILE__) + '../files/missing.yml'
    Settler.namespace = 'settings'
    assert Settler.load!
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

  def test_should_report_or_raise_missing
    #Settler.report_missing = true
    Settler.raise_missing = true

    assert_raises RuntimeError do
      Settler.missing_setting
    end
  end




end
