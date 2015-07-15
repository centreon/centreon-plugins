
package Paws::ECS::DescribeTasks {
  use Moose;
  has cluster => (is => 'ro', isa => 'Str');
  has tasks => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeTasks');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::DescribeTasksResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::DescribeTasks - Arguments for method DescribeTasks on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeTasks on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method DescribeTasks.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeTasks.

As an example:

  $service_obj->DescribeTasks(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 cluster => Str

  

The short name or full Amazon Resource Name (ARN) of the cluster that
hosts the task you want to describe. If you do not specify a cluster,
the default cluster is assumed.










=head2 B<REQUIRED> tasks => ArrayRef[Str]

  

A space-separated list of task UUIDs or full Amazon Resource Name (ARN)
entries.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeTasks in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

