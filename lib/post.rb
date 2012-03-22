require 'net/http'
require 'uri'

postData = Net::HTTP.post_form(URI.parse('http://localhost:3000/email'), 
                               {
  'from'=>'Douglas Tarr <douglas.tarr+6@gmail.com>',
  'recipient' => 'Douglas Tarr <douglas.tarr@gmail.com>',
  'subject' => 'Email test',
  'stripped-text' => 'This is a test.',
  'body-plain' => 'This is a test.'
}
                              )

puts postData.body
