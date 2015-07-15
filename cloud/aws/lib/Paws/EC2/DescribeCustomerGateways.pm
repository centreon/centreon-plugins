
package Paws::EC2::DescribeCustomerGateways {
  use Moose;
  has CustomerGatewayIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'CustomerGatewayId' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeCustomerGateways');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeCustomerGatewaysResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeCustomerGateways - Arguments for method DescribeCustomerGateways on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeCustomerGateways on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeCustomerGateways.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeCustomerGateways.

As an example:

  $service_obj->DescribeCustomerGateways(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CustomerGatewayIds => ArrayRef[Str]

  

One or more customer gateway IDs.

Default: Describes all your customer gateways.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Filters => ArrayRef[Paws::EC2::Filter]

  

One or more filters.

=over

=item *

C<bgp-asn> - The customer gateway's Border Gateway Protocol (BGP)
Autonomous System Number (ASN).

=item *

C<customer-gateway-id> - The ID of the customer gateway.

=item *

C<ip-address> - The IP address of the customer gateway's
Internet-routable external interface.

=item *

C<state> - The state of the customer gateway (C<pending> | C<available>
| C<deleting> | C<deleted>).

=item *

C<type> - The type of customer gateway. Currently, the only supported
type is C<ipsec.1>.

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

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeCustomerGateways in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

