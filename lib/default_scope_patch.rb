# Allows us to pass a lambda to default_scope. Without this, a query can be done on the database on load time, causing an
# error when the database connection hasn't been established yet.
module ActiveRecord
  class Base
    class << self
      protected
        def current_scoped_methods
          method = scoped_methods.last
          if method.respond_to?(:call)
            unscoped(&method)
          else
            method
          end
        end
    end
  end
end  
