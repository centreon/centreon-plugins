
package Paws::EC2::DescribeSubnets {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has SubnetIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'SubnetId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeSubnets');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeSubnetsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeSubnets - Arguments for method DescribeSubnets on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeSubnets on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeSubnets.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeSubnets.

As an example:

  $service_obj->DescribeSubnets(Att1 => $value1, Att2 => $value2, ...);

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

C<availabilityZone> - The Availability Zone for the subnet. You can
also use C<availability-zone> as the filter name.

=item *

C<available-ip-address-count> - The number of IP addresses in the
subnet that are available.

=item *

C<cidrBlock> - The CIDR block of the subnet. The CIDR block you specify
must exactly match the subnet's CIDR block for information to be
returned for the subnet. You can also use C<cidr> or C<cidr-block> as
the filter names.

=item *

C<defaultForAz> - Indicates whether this is the default subnet for the
Availability Zone. You can also use C<default-for-az> as the filter
name.

=item *

C<state> - The state of the subnet (C<pending> | C<available>).

=item *

C<subnet-id> - The ID of the subnet.

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

C<vpc-id> - The ID of the VPC for the subnet.

=back










=head2 SubnetIds => ArrayRef[Str]

  

One or more subnet IDs.

Default: Describes all your subnets.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeSubnets in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

