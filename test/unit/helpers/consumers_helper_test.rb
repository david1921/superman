require File.dirname(__FILE__) + "/../../test_helper"

class ConsumersHelperTest < ActionView::TestCase

   def extract_encrypted_user_id(url)
      url[url.index("userId:")+7...url.index(",")]
    end

    def extract_encrypted_token(url)
      token_start = url.index("token:")+6
      url[token_start...url.index(",", token_start)]
    end

    def extract_key(url)
      url[url.rindex("key:")+4...url.length]
    end

    context "#cyd_contest_link" do
      setup do
        @consumer = Factory(:consumer)
        @contest_link = cyd_contest_link(@consumer)
      end

      should "encrypt the user id in a way that is decryptable" do
        encrypted_user_id = extract_encrypted_user_id(@contest_link)
        key = extract_key(@contest_link)

        encryptor = Crypt::Rijndael.new(AppConfig.cyd_encryption_key + key)
        decrypted_user_id = encryptor.decrypt_block(Base64.decode64(encrypted_user_id)).strip

        assert_equal @consumer.id, decrypted_user_id.to_i
      end

      should "hash the token in a way that is repeatable" do
        key = extract_key(@contest_link)
        encrypted_token = extract_encrypted_token(@contest_link)

        first_step = Digest::MD5.hexdigest(AppConfig.cyd_token_key + key)
        final_digest = Digest::MD5.hexdigest(first_step + AppConfig.cyd_encryption_key)

        assert_equal final_digest, encrypted_token
      end

    end
end
