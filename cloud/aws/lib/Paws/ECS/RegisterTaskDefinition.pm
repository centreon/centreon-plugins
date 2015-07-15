
package Paws::ECS::RegisterTaskDefinition {
  use Moose;
  has containerDefinitions => (is => 'ro', isa => 'ArrayRef[Paws::ECS::ContainerDefinition]', required => 1);
  has family => (is => 'ro', isa => 'Str', required => 1);
  has volumes => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Volume]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RegisterTaskDefinition');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::RegisterTaskDefinitionResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::RegisterTaskDefinition - Arguments for method RegisterTaskDefinition on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method RegisterTaskDefinition on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method RegisterTaskDefinition.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RegisterTaskDefinition.

As an example:

  $service_obj->RegisterTaskDefinition(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> containerDefinitions => ArrayRef[Paws::ECS::ContainerDefinition]

  

A list of container definitions in JSON format that describe the
different containers that make up your task.










=head2 B<REQUIRED> family => Str

  

You must specify a C<family> for a task definition, which allows you to
track multiple versions of the same task definition. You can think of
the C<family> as a name for your task definition. Up to 255 letters
(uppercase and lowercase), numbers, hyphens, and underscores are
allowed.










=head2 volumes => ArrayRef[Paws::ECS::Volume]

  

A list of volume definitions in JSON format that containers in your
task may use.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RegisterTaskDefinition in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

