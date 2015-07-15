
package Paws::EC2::CreateReservedInstancesListing {
  use Moose;
  has ClientToken => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'clientToken' , required => 1);
  has InstanceCount => (is => 'ro', isa => 'Int', traits => ['NameInRequest'], request_name => 'instanceCount' , required => 1);
  has PriceSchedules => (is => 'ro', isa => 'ArrayRef[Paws::EC2::PriceScheduleSpecification]', traits => ['NameInRequest'], request_name => 'priceSchedules' , required => 1);
  has ReservedInstancesId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'reservedInstancesId' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateReservedInstancesListing');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::CreateReservedInstancesListingResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateReservedInstancesListing - Arguments for method CreateReservedInstancesListing on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateReservedInstancesListing on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CreateReservedInstancesListing.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateReservedInstancesListing.

As an example:

  $service_obj->CreateReservedInstancesListing(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ClientToken => Str

  

Unique, case-sensitive identifier you provide to ensure idempotency of
your listings. This helps avoid duplicate listings. For more
information, see Ensuring Idempotency.










=head2 B<REQUIRED> InstanceCount => Int

  

The number of instances that are a part of a Reserved Instance account
to be listed in the Reserved Instance Marketplace. This number should
be less than or equal to the instance count associated with the
Reserved Instance ID specified in this call.










=head2 B<REQUIRED> PriceSchedules => ArrayRef[Paws::EC2::PriceScheduleSpecification]

  

A list specifying the price of the Reserved Instance for each month
remaining in the Reserved Instance term.










=head2 B<REQUIRED> ReservedInstancesId => Str

  

The ID of the active Reserved Instance.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateReservedInstancesListing in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

