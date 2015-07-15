
package Paws::ECS::UpdateContainerAgent {
  use Moose;
  has cluster => (is => 'ro', isa => 'Str');
  has containerInstance => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateContainerAgent');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::UpdateContainerAgentResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::UpdateContainerAgent - Arguments for method UpdateContainerAgent on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateContainerAgent on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method UpdateContainerAgent.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateContainerAgent.

As an example:

  $service_obj->UpdateContainerAgent(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 cluster => Str

  

The short name or full Amazon Resource Name (ARN) of the cluster that
your container instance is running on. If you do not specify a cluster,
the default cluster is assumed.










=head2 B<REQUIRED> containerInstance => Str

  

The container instance UUID or full Amazon Resource Name (ARN) entries
for the container instance on which you would like to update the Amazon
ECS container agent.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateContainerAgent in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

