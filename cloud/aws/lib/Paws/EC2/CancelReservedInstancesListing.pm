
package Paws::EC2::CancelReservedInstancesListing {
  use Moose;
  has ReservedInstancesListingId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'reservedInstancesListingId' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CancelReservedInstancesListing');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::CancelReservedInstancesListingResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CancelReservedInstancesListing - Arguments for method CancelReservedInstancesListing on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CancelReservedInstancesListing on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CancelReservedInstancesListing.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CancelReservedInstancesListing.

As an example:

  $service_obj->CancelReservedInstancesListing(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ReservedInstancesListingId => Str

  

The ID of the Reserved Instance listing.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CancelReservedInstancesListing in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

