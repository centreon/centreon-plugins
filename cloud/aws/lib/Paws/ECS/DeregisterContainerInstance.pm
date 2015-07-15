
package Paws::ECS::DeregisterContainerInstance {
  use Moose;
  has cluster => (is => 'ro', isa => 'Str');
  has containerInstance => (is => 'ro', isa => 'Str', required => 1);
  has force => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeregisterContainerInstance');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::DeregisterContainerInstanceResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::DeregisterContainerInstance - Arguments for method DeregisterContainerInstance on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeregisterContainerInstance on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method DeregisterContainerInstance.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeregisterContainerInstance.

As an example:

  $service_obj->DeregisterContainerInstance(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 cluster => Str

  

The short name or full Amazon Resource Name (ARN) of the cluster that
hosts the container instance you want to deregister. If you do not
specify a cluster, the default cluster is assumed.










=head2 B<REQUIRED> containerInstance => Str

  

The container instance UUID or full Amazon Resource Name (ARN) of the
container instance you want to deregister. The ARN contains the
C<arn:aws:ecs> namespace, followed by the region of the container
instance, the AWS account ID of the container instance owner, the
C<container-instance> namespace, and then the container instance UUID.
For example,
arn:aws:ecs:I<region>:I<aws_account_id>:container-instance/I<container_instance_UUID>.










=head2 force => Bool

  

Force the deregistration of the container instance. You can use the
C<force> parameter if you have several tasks running on a container
instance and you don't want to run C<StopTask> for each task before
deregistering the container instance.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeregisterContainerInstance in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

