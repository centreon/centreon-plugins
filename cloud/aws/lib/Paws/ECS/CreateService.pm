
package Paws::ECS::CreateService {
  use Moose;
  has clientToken => (is => 'ro', isa => 'Str');
  has cluster => (is => 'ro', isa => 'Str');
  has desiredCount => (is => 'ro', isa => 'Int', required => 1);
  has loadBalancers => (is => 'ro', isa => 'ArrayRef[Paws::ECS::LoadBalancer]');
  has role => (is => 'ro', isa => 'Str');
  has serviceName => (is => 'ro', isa => 'Str', required => 1);
  has taskDefinition => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateService');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::CreateServiceResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::CreateService - Arguments for method CreateService on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateService on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method CreateService.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateService.

As an example:

  $service_obj->CreateService(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 clientToken => Str

  

Unique, case-sensitive identifier you provide to ensure the idempotency
of the request. Up to 32 ASCII characters are allowed.










=head2 cluster => Str

  

The short name or full Amazon Resource Name (ARN) of the cluster that
you want to run your service on. If you do not specify a cluster, the
default cluster is assumed.










=head2 B<REQUIRED> desiredCount => Int

  

The number of instantiations of the specified task definition that you
would like to place and keep running on your cluster.










=head2 loadBalancers => ArrayRef[Paws::ECS::LoadBalancer]

  

A list of load balancer objects, containing the load balancer name, the
container name (as it appears in a container definition), and the
container port to access from the load balancer.










=head2 role => Str

  

The name or full Amazon Resource Name (ARN) of the IAM role that allows
your Amazon ECS container agent to make calls to your load balancer on
your behalf. This parameter is only required if you are using a load
balancer with your service.










=head2 B<REQUIRED> serviceName => Str

  

The name of your service. Up to 255 letters (uppercase and lowercase),
numbers, hyphens, and underscores are allowed.










=head2 B<REQUIRED> taskDefinition => Str

  

The C<family> and C<revision> (C<family:revision>) or full Amazon
Resource Name (ARN) of the task definition that you want to run in your
service. If a C<revision> is not specified, the latest C<ACTIVE>
revision is used.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateService in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

