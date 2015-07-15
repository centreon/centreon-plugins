
package Paws::EC2::DescribeReservedInstances {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has OfferingType => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'offeringType' );
  has ReservedInstancesIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'ReservedInstancesId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeReservedInstances');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeReservedInstancesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeReservedInstances - Arguments for method DescribeReservedInstances on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeReservedInstances on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeReservedInstances.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeReservedInstances.

As an example:

  $service_obj->DescribeReservedInstances(Att1 => $value1, Att2 => $value2, ...);

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

C<availability-zone> - The Availability Zone where the Reserved
Instance can be used.

=item *

C<duration> - The duration of the Reserved Instance (one year or three
years), in seconds (C<31536000> | C<94608000>).

=item *

C<end> - The time when the Reserved Instance expires (for example,
2015-08-07T11:54:42.000Z).

=item *

C<fixed-price> - The purchase price of the Reserved Instance (for
example, 9800.0).

=item *

C<instance-type> - The instance type on which the Reserved Instance can
be used.

=item *

C<product-description> - The Reserved Instance product platform
description. Instances that include C<(Amazon VPC)> in the product
platform description will only be displayed to EC2-Classic account
holders and are for use with Amazon VPC. (C<Linux/UNIX> | C<Linux/UNIX
(Amazon VPC)> | C<SUSE Linux> | C<SUSE Linux (Amazon VPC)> | C<Red Hat
Enterprise Linux> | C<Red Hat Enterprise Linux (Amazon VPC)> |
C<Windows> | C<Windows (Amazon VPC)> | C<Windows with SQL Server
Standard> | C<Windows with SQL Server Standard (Amazon VPC)> |
C<Windows with SQL Server Web> | C<Windows with SQL Server Web (Amazon
VPC)>).

=item *

C<reserved-instances-id> - The ID of the Reserved Instance.

=item *

C<start> - The time at which the Reserved Instance purchase request was
placed (for example, 2014-08-07T11:54:42.000Z).

=item *

C<state> - The state of the Reserved Instance (C<payment-pending> |
C<active> | C<payment-failed> | C<retired>).

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

C<usage-price> - The usage price of the Reserved Instance, per hour
(for example, 0.84).

=back










=head2 OfferingType => Str

  

The Reserved Instance offering type. If you are using tools that
predate the 2011-11-01 API version, you only have access to the
C<Medium Utilization> Reserved Instance offering type.










=head2 ReservedInstancesIds => ArrayRef[Str]

  

One or more Reserved Instance IDs.

Default: Describes all your Reserved Instances, or only those otherwise
specified.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeReservedInstances in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

