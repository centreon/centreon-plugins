
package Paws::ECS::StopTask {
  use Moose;
  has cluster => (is => 'ro', isa => 'Str');
  has task => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'StopTask');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::StopTaskResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::StopTask - Arguments for method StopTask on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method StopTask on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method StopTask.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to StopTask.

As an example:

  $service_obj->StopTask(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 cluster => Str

  

The short name or full Amazon Resource Name (ARN) of the cluster that
hosts the task you want to stop. If you do not specify a cluster, the
default cluster is assumed..










=head2 B<REQUIRED> task => Str

  

The task UUIDs or full Amazon Resource Name (ARN) entry of the task you
would like to stop.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method StopTask in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

