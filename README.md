# Resolv SRV

Resolve and iterate over SRV DNS records correctly.

## Links

* Homepage :: https://github.com/javanthropus/resolv-srv
* Source :: https://github.com/javanthropus/resolv-srv.git

## Description

This gem patches the Resolv::DNS class in stdlib to include a method to resolve
and iterate over SRV records according to their relative priorities and weights.

## Features

* Iterate over SRV resources in order by priority and randomly in proportion to
  weight.

## Known Bugs/Limitations

* None so far...

## Synopsis

Look up your user information in Active Directory (assumes `/etc/ssl/certs`
contains the internal CA certificate for the domain):

```ruby
#!/usr/bin/env ruby

require 'net/ldap'
require 'pp'
require 'resolv-srv'

def search_ldap(domain, username, password, search_args = {})
  base = domain.split('.').map { |n| "dc=#{n}" }.join(',')
  Resolv::DNS.open do |dns|
    dns.each_srv_resource('ldap', 'tcp', domain) do |srv|
      begin
        Net::LDAP.open(
          host: srv.target.to_s,
          port: srv.port,
          base: base,
          auth: {
            method: :simple,
            username: username,
            password: password,
          },
          encryption: {
            method: :start_tls,
            tls_options: { ca_path: '/etc/ssl/certs' }
          },
        ) do |ldap|
          return ldap.search(search_args)
        end
      rescue Net::LDAP::Error, OpenSSL::SSL::SSLError
        puts "Failed with host #{srv.target} on port #{srv.port}: #{$!}"
      end
    end
  end
end

print 'AD Domain: '
domain = gets.chomp
print 'AD Username: '
username = gets.chomp
print "AD Password (#{username}): "
password = ($stdin.tty? ? $stdin.noecho(&:gets) : $stdin.gets).chomp
puts

pp search_ldap(
  domain,
  "#{username}@#{domain}",
  password,
  filter: "sAMAccountName=#{username}"
)
```

## Requirements

None

## Contributing

Contributions for bug fixes, documentation, extensions, tests, etc. are
encouraged.

1. Clone the repository.
2. Fix a bug or add a feature.
3. Add tests for the fix or feature.
4. Make a pull request.

## Development

After checking out the source, run:

    $ bundle install
    $ bundle exec rake test yard

This will install all dependencies, run the tests/specs, and generate the
documentation.

## Authors

Thanks to all contributors.  Without your help this project would not exist.

* Jeremy Bopp :: jeremy@bopp.net

## License

```
(The MIT License)

Copyright (c) 2015 Jeremy Bopp

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
