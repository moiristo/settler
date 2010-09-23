ActiveRecord::Schema.define(:version => 0) do   
  create_table :settings, :force => true do |t|
    t.string  :key, :null => false
    t.string  :alt
    t.text    :value
    t.boolean :editable
    t.boolean :deletable
    t.boolean :deleted      
    t.timestamps
  end
end