
package Paws::EC2::DescribeReservedInstancesListings {
  use Moose;
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'filters' );
  has ReservedInstancesId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'reservedInstancesId' );
  has ReservedInstancesListingId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'reservedInstancesListingId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeReservedInstancesListings');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeReservedInstancesListingsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeReservedInstancesListings - Arguments for method DescribeReservedInstancesListings on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeReservedInstancesListings on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeReservedInstancesListings.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeReservedInstancesListings.

As an example:

  $service_obj->DescribeReservedInstancesListings(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Filters => ArrayRef[Paws::EC2::Filter]

  

One or more filters.

=over

=item *

C<reserved-instances-id> - The ID of the Reserved Instances.

=item *

C<reserved-instances-listing-id> - The ID of the Reserved Instances
listing.

=item *

C<status> - The status of the Reserved Instance listing (C<pending> |
C<active> | C<cancelled> | C<closed>).

=item *

C<status-message> - The reason for the status.

=back










=head2 ReservedInstancesId => Str

  

One or more Reserved Instance IDs.










=head2 ReservedInstancesListingId => Str

  

One or more Reserved Instance Listing IDs.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeReservedInstancesListings in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

