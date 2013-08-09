require 'test_helper'

class TestSettler < Test::Unit::TestCase
  def setup
    Setting.delete_all
    Settler.source = File.dirname(__FILE__) + '/settler.yml'
    Settler.namespace = 'settings'    
    Settler.load!
  end
  
  def test_should_not_crash_if_config_missing
    Settler.source = File.dirname(__FILE__) + '/missing.yml'
    Settler.namespace = 'settings'
    
    assert_nothing_raised do
      Settler.load!
    end
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
  
  def test_should_not_create_instance
    assert_nil Settler.new
  end
  
  def test_should_report_or_raise_missing    
    #Settler.report_missing = true    
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
  
  def test_should_delete_destroyed_setting
    deletable_setting = Settler.search_algorithm
    assert deletable_setting.destroy
    deletable_setting.delete
    assert Setting.deleted.empty?
    Settler.load!
    assert Settler.search_algorithm.present?
  end  

  def test_should_delete_all_destroyed_setting
    deletable_setting = Settler.search_algorithm
    assert deletable_setting.destroy
    Setting.delete_all
    assert Setting.deleted.empty?
    Settler.load!
    assert Settler.search_algorithm.present?
  end    
  
  def test_should_not_update_uneditable_setting
    uneditable_setting = Settler.search_algorithm
    assert !uneditable_setting.update_attributes(:value => 'sphinx')
    assert uneditable_setting.errors[:base].any?
    assert_equal 'ferret', Settler[:search_algorithm]
  end
  
  def test_should_manually_update_uneditable_setting
    uneditable_setting = Settler.search_algorithm
    assert uneditable_setting.update_attribute(:value, 'sphinx')
    assert uneditable_setting.errors[:value].empty?
    assert_equal 'sphinx', Settler[:search_algorithm]
  end  
  
  def test_should_update_editable_setting
    editable_setting = Settler.google_analytics_key
    assert editable_setting.update_attributes(:value => 'UA-xxxxxx-1')
    assert_equal 'UA-xxxxxx-1', Settler[:google_analytics_key]
  end
  
  def test_key_should_be_readonly_attribute
    setting = Settler.google_analytics_key
    setting.update_attribute(:key, 'new_key') rescue nil
    assert_equal 'google_analytics_key', setting.reload.key
  end
  
  def test_should_not_update_uneditable_settings
    setting = Settler.google_analytics_key    
    assert !setting.update_attributes(:key => 'new_key', :label => 'new_label', :value => 'UA-xxxxxx-1', :editable => false, :deletable => true, :deleted => true)
    assert setting.errors[:base].any?
  end
  
  def test_should_get_scopes
    assert_equal [Settler.google_analytics_key], Setting.editable
    assert_equal [Settler.search_algorithm], Setting.deletable

    assert_equal [], Setting.deleted        
    deletable_setting = Settler.search_algorithm
    assert deletable_setting.destroy
    assert_equal [deletable_setting], Setting.deleted    
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
    bool_setting.update_attribute(:value, false)      
    assert_equal false, bool_setting.value    
    bool_setting.update_attribute(:value, 'f')      
    assert_equal false, bool_setting.value      
    bool_setting.update_attribute(:value, 'bla')      
    assert_equal false, bool_setting.value          
    bool_setting.update_attribute(:value, 't')      
    assert_equal true, bool_setting.value     
    bool_setting.update_attribute(:value, 'true')      
    assert_equal true, bool_setting.value  
    bool_setting.update_attribute(:value, 'TrUe')      
    assert_equal true, bool_setting.value    
    bool_setting.update_attribute(:value, 'tr')      
    assert_equal false, bool_setting.value        
  end
  
  def test_password_typecaster  
    password_value = Settler.password_value
    assert_not_equal '123456', password_value.untypecasted_value  
    assert_not_equal password_value.value, password_value.untypecasted_value      
    assert_equal '123456', password_value.value        
  end
  
  def test_should_validate_format
    setting = Settler.google_analytics_key
    assert !setting.update_attributes(:value => 'invalid_format')    
  end
  
  def test_should_reset_setting
    uneditable_setting = Settler.search_algorithm
    assert uneditable_setting.update_attribute(:deletable, false)
    assert uneditable_setting.update_attribute(:value, 'sphinx')
    assert_equal 'sphinx', Settler[:search_algorithm]
    assert !uneditable_setting.deletable?
    
    uneditable_setting.reset!
    assert_equal 'ferret', Settler[:search_algorithm] 
    assert uneditable_setting.deletable?    
  end  
  
  def test_should_undelete_when_resetting
    deleted_setting = Settler.search_algorithm
    assert deleted_setting.destroy
    assert Setting.deleted.include?(deleted_setting)
    deleted_setting.reset!
    assert !Setting.deleted.include?(deleted_setting)    
  end
  
  def test_should_return_type
    assert Settler.integer_value.type.integer?
    assert Settler.float_value.type.float?
    assert Settler.bool_value.type.boolean? 
    assert Settler.password_value.type.password?   
    assert Settler.datetime_value.type.datetime?
    assert Settler.custom_value.type.string?
    assert_equal 'string', Settler.search_algorithm.type    
  end
  
end
