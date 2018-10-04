require 'securerandom'

module Cryppo
  module KeyDerivationStrategies
    class Pbkdf2Hmac < KeyDerivationStrategy

      attr_reader :min_iterations, :variance

      def initialize(min_iterations: 20000, iteration_variance: 10)
        @min_iterations = min_iterations
        @variance = (min_iterations * (iteration_variance / 100.0)).to_i
        @variance = 1 if @variance == 0
      end

      def generate_derived_key(key, key_length: 32)
        salt = OpenSSL::Random.random_bytes(20)
        iterations = min_iterations + SecureRandom.random_number(variance) # provide some randomisation to the number of iterations
        derived_key = OpenSSL::KDF.pbkdf2_hmac(key, salt: salt, iterations: iterations, length: key_length, hash: OpenSSL::Digest::SHA256.new)
        wrapped_derived_key = wrap_encryption_key(derived_key)
        EncryptionValues::DerivedKey.new(self, wrapped_derived_key, salt: salt, iter: iterations, length: key_length, hash: 'SHA256')
      end

      def build_derived_key(key, derived_key_value)
        salt, iterations, key_length = derived_key_value.derivation_artefacts.values_at(:salt, :iter, :length)
        OpenSSL::KDF.pbkdf2_hmac(key, salt: salt, iterations: iterations, length: key_length, hash: OpenSSL::Digest::SHA256.new)
      end

    end
  end
end