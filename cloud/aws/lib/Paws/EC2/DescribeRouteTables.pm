
package Paws::EC2::DescribeRouteTables {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has RouteTableIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'RouteTableId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeRouteTables');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeRouteTablesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeRouteTables - Arguments for method DescribeRouteTables on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeRouteTables on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeRouteTables.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeRouteTables.

As an example:

  $service_obj->DescribeRouteTables(Att1 => $value1, Att2 => $value2, ...);

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

C<association.route-table-association-id> - The ID of an association ID
for the route table.

=item *

C<association.route-table-id> - The ID of the route table involved in
the association.

=item *

C<association.subnet-id> - The ID of the subnet involved in the
association.

=item *

C<association.main> - Indicates whether the route table is the main
route table for the VPC.

=item *

C<route-table-id> - The ID of the route table.

=item *

C<route.destination-cidr-block> - The CIDR range specified in a route
in the table.

=item *

C<route.destination-prefix-list-id> - The ID (prefix) of the AWS
service specified in a route in the table.

=item *

C<route.gateway-id> - The ID of a gateway specified in a route in the
table.

=item *

C<route.instance-id> - The ID of an instance specified in a route in
the table.

=item *

C<route.origin> - Describes how the route was created.
C<CreateRouteTable> indicates that the route was automatically created
when the route table was created; C<CreateRoute> indicates that the
route was manually added to the route table;
C<EnableVgwRoutePropagation> indicates that the route was propagated by
route propagation.

=item *

C<route.state> - The state of a route in the route table (C<active> |
C<blackhole>). The blackhole state indicates that the route's target
isn't available (for example, the specified gateway isn't attached to
the VPC, the specified NAT instance has been terminated, and so on).

=item *

C<route.vpc-peering-connection-id> - The ID of a VPC peering connection
specified in a route in the table.

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

C<vpc-id> - The ID of the VPC for the route table.

=back










=head2 RouteTableIds => ArrayRef[Str]

  

One or more route table IDs.

Default: Describes all your route tables.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeRouteTables in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

