require 'minitest/autorun'
require 'minitest/mock'
require 'minitest/spec'

require 'resolv-srv'

describe "each_srv_resource" do
  before do
    @dns = Resolv::DNS.new
    domain = 'example.com'
    hostname_template = "foo%i-%i-%i.#{domain}"
    @prioritized_weights = [
      [0, 0, 100, 400, 400],
      [100],
      [400, 400],
      [1, 2, 3, 4, 5],
    ]
    @srv_resources =
      @prioritized_weights.
      to_enum(:each_with_index).
      flat_map do |weights, priority|
        weights.each_with_index.map do |weight, n|
          Resolv::DNS::Resource::IN::SRV.new(
            priority, weight, 12345, hostname_template % [n, priority, weight]
          )
        end
      end.shuffle
  end

  after do
    @dns.close
  end

  it 'raises an exception if the service name is invalid' do
    -> {
      @dns.each_srv_resource('bad.service.name', 'tcp', 'example.com') {}
    }.must_raise(ArgumentError)
  end

  it 'raises an exception if the service name is empty' do
    -> {
      @dns.each_srv_resource('', 'tcp', 'example.com') {}
    }.must_raise(ArgumentError)
  end

  it 'raises an exception if the service name is nil' do
    -> {
      @dns.each_srv_resource(nil, 'tcp', 'example.com') {}
    }.must_raise(ArgumentError)
  end

  it 'raises an exception if the protocol name is invalid' do
    -> {
      @dns.each_srv_resource('ldap', 'bad.protocol.name', 'example.com') {}
    }.must_raise(ArgumentError)
  end

  it 'raises an exception if the protocol name is empty' do
    -> {
      @dns.each_srv_resource('ldap', '', 'example.com') {}
    }.must_raise(ArgumentError)
  end

  it 'raises an exception if the protocol name is nil' do
    -> {
      @dns.each_srv_resource('ldap', nil, 'example.com') {}
    }.must_raise(ArgumentError)
  end

  it 'orders by priority' do
    @dns.stub(:getresources, @srv_resources) do
      @dns.to_enum(:each_srv_resource, 'ldap', 'tcp', 'example.com').
        map do |srv|
          srv.priority
        end.
        must_equal(
          @prioritized_weights.
          to_enum(:each_with_index).
          flat_map do |weights, priority|
            [priority] * weights.size
          end
        )
    end
  end

  it 'orders randomly in proportion to weight' do
    results = Hash.new do |h, priority|
      h[priority] = Hash.new do |h2, srv|
        h2[srv] = Array.new(@prioritized_weights[priority].size, 0)
      end
    end

    rounds = 100_000
    @dns.stub(:getresources, @srv_resources) do
      rounds.times do
        selection = -1
        old_priority = 0
        @dns.each_srv_resource('ldap', 'tcp', 'example.com') do |srv|
          if srv.priority != old_priority
            old_priority = srv.priority
            selection = 0
          else
            selection += 1
          end

          results[srv.priority][srv][selection] += 1
        end
      end
    end

    results.each do |priority, srv_selections|
      srv_selections.each do |srv, selections|
        selections.each_with_index do |hits, position|
          expected = expected_probability(
            position, srv.weight, @prioritized_weights[priority]
          )
          actual = Float(hits) / rounds
          actual.must_be_close_to(expected, 0.02)
        end
      end
    end
  end

  def expected_probability(position, selected_weight, weights)
    return first_probability(selected_weight, weights) if position == 0

    simple_remove(weights, selected_weight).inject(0) do |sum, w|
      sum +
        first_probability(w, weights) *
        expected_probability(
          position - 1, selected_weight, simple_remove(weights, w)
        )
    end
  end

  def first_probability(selected_weight, weights)
    total_weight = weights.inject(0) { |sum, weight| sum + weight + 1 }
    Float(selected_weight + 1) / total_weight
  end

  def simple_remove(array, element)
    array = array.dup
    array.delete_at(array.find_index(element))
    array
  end
end
