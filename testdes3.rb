require "base64"
require "openssl"

def encrypt(data)
  cipher = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
  cipher.encrypt # Must be called before anything else

  # Generate the key and initialization vector for the algorithm.
  # Alternatively, you can specify the initialization vector and cipher key
  # specifically using `cipher.iv = 'some iv'` and `cipher.key = 'some key'`
  #cipher.pkcs5_keyivgen('SOME_PASS_PHRASE_GOES_HERE')
  cipher.iv='XXXX2014'
  cipher.key='12345678901234567890123A'
  
  output = cipher.update(data)
  output << cipher.final
  output
end

def decrypt(data)
  # Effectively the same as the `encrypt` method
  cipher = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
  cipher.decrypt # Also must be called before anything else

  #cipher.pkcs5_keyivgen('SOME_PASS_PHRASE_GOES_HERE')
  
  cipher.iv='XXXX2014'
  cipher.key='12345678901234567890123A'
  
  output = cipher.update(data)
  output << cipher.final
  output
end

b64_encrypted_string = Base64.encode64(encrypt('blowme'))
puts b64_encrypted_string
#=> "some base 64 encoded string"

decrypted_string = decrypt(Base64.decode64(b64_encrypted_string))
puts decrypted_string
