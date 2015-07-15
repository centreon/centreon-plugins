
package Paws::ECS::SubmitTaskStateChange {
  use Moose;
  has cluster => (is => 'ro', isa => 'Str');
  has reason => (is => 'ro', isa => 'Str');
  has status => (is => 'ro', isa => 'Str');
  has task => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SubmitTaskStateChange');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::SubmitTaskStateChangeResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::SubmitTaskStateChange - Arguments for method SubmitTaskStateChange on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method SubmitTaskStateChange on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method SubmitTaskStateChange.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SubmitTaskStateChange.

As an example:

  $service_obj->SubmitTaskStateChange(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 cluster => Str

  

The short name or full Amazon Resource Name (ARN) of the cluster that
hosts the task.










=head2 reason => Str

  

The reason for the state change request.










=head2 status => Str

  

The status of the state change request.










=head2 task => Str

  

The task UUID or full Amazon Resource Name (ARN) of the task in the
state change request.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SubmitTaskStateChange in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

