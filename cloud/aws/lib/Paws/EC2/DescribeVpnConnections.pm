
package Paws::EC2::DescribeVpnConnections {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has VpnConnectionIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'VpnConnectionId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeVpnConnections');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeVpnConnectionsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeVpnConnections - Arguments for method DescribeVpnConnections on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeVpnConnections on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeVpnConnections.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeVpnConnections.

As an example:

  $service_obj->DescribeVpnConnections(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Filters => ArrayRef[Paws::EC2::Filter]

  

One or more filters.

=over

=item *

C<customer-gateway-configuration> - The configuration information for
the customer gateway.

=item *

C<customer-gateway-id> - The ID of a customer gateway associated with
the VPN connection.

=item *

C<state> - The state of the VPN connection (C<pending> | C<available> |
C<deleting> | C<deleted>).

=item *

C<option.static-routes-only> - Indicates whether the connection has
static routes only. Used for devices that do not support Border Gateway
Protocol (BGP).

=item *

C<route.destination-cidr-block> - The destination CIDR block. This
corresponds to the subnet used in a customer data center.

=item *

C<bgp-asn> - The BGP Autonomous System Number (ASN) associated with a
BGP device.

=item *

C<tag>:I<key>=I<value> - The key/value combination of a tag assigned to
the resource.

=item *

C<tag-key> - The key of a tag assigned to the resource. This filter is
independent of the C<tag-value> filter. For example, if you use both
the filter "tag-key=Purpose" and the filter "tag-value=X", you get any
resources assigned both the tag key Purpose (regardless of what the
tag's value is), and the tag value X (regardless of what the tag's key
is). If you want to list only resources where Purpose is X, see the
C<tag>:I<key>=I<value> filter.

=item *

C<tag-value> - The value of a tag assigned to the resource. This filter
is independent of the C<tag-key> filter.

=item *

C<type> - The type of VPN connection. Currently the only supported type
is C<ipsec.1>.

=item *

C<vpn-connection-id> - The ID of the VPN connection.

=item *

C<vpn-gateway-id> - The ID of a virtual private gateway associated with
the VPN connection.

=back










=head2 VpnConnectionIds => ArrayRef[Str]

  

One or more VPN connection IDs.

Default: Describes your VPN connections.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeVpnConnections in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

