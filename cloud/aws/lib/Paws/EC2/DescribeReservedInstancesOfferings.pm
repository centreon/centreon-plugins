
package Paws::EC2::DescribeReservedInstancesOfferings {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str');
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has IncludeMarketplace => (is => 'ro', isa => 'Bool');
  has InstanceTenancy => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'instanceTenancy' );
  has InstanceType => (is => 'ro', isa => 'Str');
  has MaxDuration => (is => 'ro', isa => 'Int');
  has MaxInstanceCount => (is => 'ro', isa => 'Int');
  has MaxResults => (is => 'ro', isa => 'Int', traits => ['NameInRequest'], request_name => 'maxResults' );
  has MinDuration => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'nextToken' );
  has OfferingType => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'offeringType' );
  has ProductDescription => (is => 'ro', isa => 'Str');
  has ReservedInstancesOfferingIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'ReservedInstancesOfferingId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeReservedInstancesOfferings');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeReservedInstancesOfferingsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeReservedInstancesOfferings - Arguments for method DescribeReservedInstancesOfferings on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeReservedInstancesOfferings on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeReservedInstancesOfferings.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeReservedInstancesOfferings.

As an example:

  $service_obj->DescribeReservedInstancesOfferings(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AvailabilityZone => Str

  

The Availability Zone in which the Reserved Instance can be used.










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

C<duration> - The duration of the Reserved Instance (for example, one
year or three years), in seconds (C<31536000> | C<94608000>).

=item *

C<fixed-price> - The purchase price of the Reserved Instance (for
example, 9800.0).

=item *

C<instance-type> - The instance type on which the Reserved Instance can
be used.

=item *

C<marketplace> - Set to C<true> to show only Reserved Instance
Marketplace offerings. When this filter is not used, which is the
default behavior, all offerings from AWS and Reserved Instance
Marketplace are listed.

=item *

C<product-description> - The Reserved Instance product platform
description. Instances that include C<(Amazon VPC)> in the product
platform description will only be displayed to EC2-Classic account
holders and are for use with Amazon VPC. (C<Linux/UNIX> | C<Linux/UNIX
(Amazon VPC)> | C<SUSE Linux> | C<SUSE Linux (Amazon VPC)> | C<Red Hat
Enterprise Linux> | C<Red Hat Enterprise Linux (Amazon VPC)> |
C<Windows> | C<Windows (Amazon VPC)>) | C<Windows with SQL Server
Standard> | C<Windows with SQL Server Standard (Amazon VPC)> |
C<Windows with SQL Server Web> | C< Windows with SQL Server Web (Amazon
VPC))>

=item *

C<reserved-instances-offering-id> - The Reserved Instances offering ID.

=item *

C<usage-price> - The usage price of the Reserved Instance, per hour
(for example, 0.84).

=back










=head2 IncludeMarketplace => Bool

  

Include Marketplace offerings in the response.










=head2 InstanceTenancy => Str

  

The tenancy of the Reserved Instance offering. A Reserved Instance with
C<dedicated> tenancy runs on single-tenant hardware and can only be
launched within a VPC.

Default: C<default>










=head2 InstanceType => Str

  

The instance type on which the Reserved Instance can be used. For more
information, see Instance Types in the I<Amazon Elastic Compute Cloud
User Guide>.










=head2 MaxDuration => Int

  

The maximum duration (in seconds) to filter when searching for
offerings.

Default: 94608000 (3 years)










=head2 MaxInstanceCount => Int

  

The maximum number of instances to filter when searching for offerings.

Default: 20










=head2 MaxResults => Int

  

The maximum number of results to return for the request in a single
page. The remaining results of the initial request can be seen by
sending another request with the returned C<NextToken> value. The
maximum is 100.

Default: 100










=head2 MinDuration => Int

  

The minimum duration (in seconds) to filter when searching for
offerings.

Default: 2592000 (1 month)










=head2 NextToken => Str

  

The token to retrieve the next page of results.










=head2 OfferingType => Str

  

The Reserved Instance offering type. If you are using tools that
predate the 2011-11-01 API version, you only have access to the
C<Medium Utilization> Reserved Instance offering type.










=head2 ProductDescription => Str

  

The Reserved Instance product platform description. Instances that
include C<(Amazon VPC)> in the description are for use with Amazon VPC.










=head2 ReservedInstancesOfferingIds => ArrayRef[Str]

  

One or more Reserved Instances offering IDs.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeReservedInstancesOfferings in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

