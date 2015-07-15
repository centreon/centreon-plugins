
package Paws::EC2::ModifyReservedInstances {
  use Moose;
  has ClientToken => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'clientToken' );
  has ReservedInstancesIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'ReservedInstancesId' , required => 1);
  has TargetConfigurations => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ReservedInstancesConfiguration]', traits => ['NameInRequest'], request_name => 'ReservedInstancesConfigurationSetItemType' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyReservedInstances');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::ModifyReservedInstancesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ModifyReservedInstances - Arguments for method ModifyReservedInstances on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyReservedInstances on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method ModifyReservedInstances.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyReservedInstances.

As an example:

  $service_obj->ModifyReservedInstances(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ClientToken => Str

  

A unique, case-sensitive token you provide to ensure idempotency of
your modification request. For more information, see Ensuring
Idempotency.










=head2 B<REQUIRED> ReservedInstancesIds => ArrayRef[Str]

  

The IDs of the Reserved Instances to modify.










=head2 B<REQUIRED> TargetConfigurations => ArrayRef[Paws::EC2::ReservedInstancesConfiguration]

  

The configuration settings for the Reserved Instances to modify.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyReservedInstances in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

