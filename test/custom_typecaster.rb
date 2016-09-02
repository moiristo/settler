class CustomTypecaster < Settler::Typecaster
  def typecast(value)
    'custom value'
  end
end