module Settler
  module Typecasters
    # Casts a value to a password by encoding the passed value
    class PasswordTypecaster < Settler::Typecaster
      def type; 'password' end

      def typecast(value)
        if message_encryptor
          message_encryptor.decrypt_and_verify(value.to_s)
        else
          Settler.warn('[Settler] ActiveSupport is required when using the password-typecaster')
          value
        end
      end

      def typecast_on_write(value)
        if message_encryptor
          message_encryptor.encrypt_and_sign(value.to_s)
        else
          Settler.warn('[Settler] ActiveSupport is required when using the password-typecaster')
          value
        end
      end

      def typecast_on_write?
        true # force typecast on write
      end

      def message_encryptor
        @message_encryptor ||= ActiveSupport::MessageEncryptor.new(Settler.password_secret || '01234567890123456789012345678901') if defined?(ActiveSupport)
      end
    end
  end
end