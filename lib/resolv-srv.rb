require 'resolv'

##
# A monkey patch for Resolv::DNS that provides a mostly RFC-compliant method for
# resolving SRV records.
class Resolv::DNS
  ##
  # Iterates over SRV resources for _service_ operating over _protocol_ within
  # _domain_, first in order of priority and then randomly within a priority in
  # proportion to weight.
  #
  # *NOTE:* The algorithm used causes resources with weight 0 to be selected
  # before resources with higher weights slightly more often than they would be
  # if strict RFC compliance were enforced.
  #
  # @param service [String] The service type, such as +ldap+ or +http+.
  # @param protocol [String] The protocol for connections, such as +tcp+ or
  #                          +udp+.
  # @param domain [String] The DNS domain in which to search for records.
  #
  # @yield Resolv::DNS::Resource::IN::SRV
  def each_srv_resource(service, protocol, domain)
    if service.nil? || service.empty? || service.index('.')
      raise ArgumentError, "Invalid service name: #{service.inspect}"
    end
    if protocol.nil? || protocol.empty? || protocol.index('.')
      raise ArgumentError, "Invalid protocol name: #{protocol.inspect}"
    end

    name = "_#{service}._#{protocol}.#{domain}"

    # Fetch the resources.
    getresources(name, Resolv::DNS::Resource::IN::SRV).
    # Group and sort them by priority.
    sort_by!(&:priority).chunk(&:priority).sort.
    # Iterate over the lists of resources at each priority level.
    each do |priority, available|
      # NOTE:
      # All weight processing is shifted to be 1-based rather than 0-based.
      # Because of the way selection is handled, this avoids needing to shuffle
      # or sort the array elements by weight while ensuring that resources with
      # weight 0 avoid ALWAYS being selected last.  The trade-off is that
      # resources with weight 0 may be selected before other resources slightly
      # more often than otherwise.

      # Tracks the total weight of all resources remaining in the available
      # list.
      total_weight = available.inject(0) { |sum, e| sum + e.weight + 1 }

      until available.empty?
        # Randomly select from the available list such that the probability of
        # selecting a resource is proportional to the resource's weight.
        selector = Integer(rand * total_weight) + 1
        selected_idx = available.find_index do |e|
          selector -= e.weight + 1
          selector <= 0
        end
        selected = available.delete_at(selected_idx)

        # Account for the removal of a resource from the available list.
        total_weight -= selected.weight + 1

        yield(selected)
      end
    end
  end
end
