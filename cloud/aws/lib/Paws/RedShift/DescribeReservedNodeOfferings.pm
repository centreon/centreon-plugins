
package Paws::RedShift::DescribeReservedNodeOfferings {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has ReservedNodeOfferingId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeReservedNodeOfferings');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::ReservedNodeOfferingsMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeReservedNodeOfferingsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::DescribeReservedNodeOfferings - Arguments for method DescribeReservedNodeOfferings on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeReservedNodeOfferings on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method DescribeReservedNodeOfferings.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeReservedNodeOfferings.

As an example:

  $service_obj->DescribeReservedNodeOfferings(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Marker => Str

  

An optional parameter that specifies the starting point to return a set
of response records. When the results of a
DescribeReservedNodeOfferings request exceed the value specified in
C<MaxRecords>, AWS returns a value in the C<Marker> field of the
response. You can retrieve the next set of response records by
providing the returned marker value in the C<Marker> parameter and
retrying the request.










=head2 MaxRecords => Int

  

The maximum number of response records to return in each call. If the
number of remaining response records exceeds the specified
C<MaxRecords> value, a value is returned in a C<marker> field of the
response. You can retrieve the next set of records by retrying the
command with the returned marker value.

Default: C<100>

Constraints: minimum 20, maximum 100.










=head2 ReservedNodeOfferingId => Str

  

The unique identifier for the offering.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeReservedNodeOfferings in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

