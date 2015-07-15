
package Paws::ECS::DeregisterTaskDefinition {
  use Moose;
  has taskDefinition => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeregisterTaskDefinition');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::DeregisterTaskDefinitionResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::DeregisterTaskDefinition - Arguments for method DeregisterTaskDefinition on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeregisterTaskDefinition on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method DeregisterTaskDefinition.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeregisterTaskDefinition.

As an example:

  $service_obj->DeregisterTaskDefinition(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> taskDefinition => Str

  

The C<family> and C<revision> (C<family:revision>) or full Amazon
Resource Name (ARN) of the task definition that you want to deregister.
You must specify a C<revision>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeregisterTaskDefinition in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

