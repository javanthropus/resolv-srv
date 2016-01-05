#!/usr/bin/env ruby

require 'net/ldap'
require 'pp'
require 'resolv-srv'

class LDAPServerList
  include Enumerable

  def initialize(domain)
    @domain = domain
  end

  def each
    Resolv::DNS.open do |dns|
      dns.each_srv_resource('ldap', 'tcp', @domain) do |srv|
        yield(srv.target.to_s, srv.port)
      end
    end
  end
end

def search_ldap(domain, username, password, search_args = {})
  base = domain.split('.').map { |n| "dc=#{n}" }.join(',')
  Net::LDAP.open(
    hosts: LDAPServerList.new(domain),
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
