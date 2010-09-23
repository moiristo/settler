require 'helper'

class TestSettler < Test::Unit::TestCase
  load_schema
  
  def setup
    Setting.without_default_scope{ Setting.delete_all }
    Settler.source = File.dirname(__FILE__) + '/settler.yml'
    Settler.namespace = 'settings'    
    Settler.load!
  end
    
  def test_should_load_settings
    assert_equal ['google_analytics_key', 'search_algorithm'], Settler.settings
  end
  
  def test_should_find_setting_value
    assert_equal 'ferret', Settler[:search_algorithm]
    assert_equal 'ferret', Settler.search_algorithm.value
  end
  
  def test_should_get_validations_for_setting
    assert_equal({'presence' => true}, Settler.validations_for(:google_analytics_key))
    assert_equal({"inclusion"=>["ferret", "sphinx"]}, Settler.validations_for(:search_algorithm))
  end
  
  def test_should_not_create_instance
    assert_raise NoMethodError do 
      Settler.new
    end
  end
  
  def test_should_report_or_raise_missing    
    Settler.report_missing = true    
    Settler.raise_missing = true
    
    assert_raise RuntimeError do
      Settler.missing_setting 
    end      
  end
  
  def test_should_not_destroy_undeletable_setting
    assert !Settler.google_analytics_key.destroy
    assert !Settler.google_analytics_key.deleted?
  end
  
  def test_should_destroy_setting
    deletable_setting = Settler.search_algorithm
    assert deletable_setting.deletable?
    assert deletable_setting.destroy
    assert_equal true, deletable_setting.deleted?
    Settler.load!
    assert_nil Settler.search_algorithm
  end
  
  def test_should_not_update_uneditable_setting
    uneditable_setting = Settler.search_algorithm
    assert !uneditable_setting.update_attributes(:value => 'new_value')
    assert_equal 'ferret', Settler[:search_algorithm]
  end
  
  def test_should_update_editable_setting
    editable_setting = Settler.google_analytics_key
    assert editable_setting.update_attributes(:value => 'new_value')
    assert_equal 'new_value', Settler[:google_analytics_key]
  end  
  
end
