
package Paws::ECS::DiscoverPollEndpoint {
  use Moose;
  has cluster => (is => 'ro', isa => 'Str');
  has containerInstance => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DiscoverPollEndpoint');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::DiscoverPollEndpointResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::DiscoverPollEndpoint - Arguments for method DiscoverPollEndpoint on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DiscoverPollEndpoint on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method DiscoverPollEndpoint.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DiscoverPollEndpoint.

As an example:

  $service_obj->DiscoverPollEndpoint(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 cluster => Str

  

The cluster that the container instance belongs to.










=head2 containerInstance => Str

  

The container instance UUID or full Amazon Resource Name (ARN) of the
container instance. The ARN contains the C<arn:aws:ecs> namespace,
followed by the region of the container instance, the AWS account ID of
the container instance owner, the C<container-instance> namespace, and
then the container instance UUID. For example,
arn:aws:ecs:I<region>:I<aws_account_id>:container-instance/I<container_instance_UUID>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DiscoverPollEndpoint in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

