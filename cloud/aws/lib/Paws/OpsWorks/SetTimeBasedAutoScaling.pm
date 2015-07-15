
package Paws::OpsWorks::SetTimeBasedAutoScaling {
  use Moose;
  has AutoScalingSchedule => (is => 'ro', isa => 'Paws::OpsWorks::WeeklyAutoScalingSchedule');
  has InstanceId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetTimeBasedAutoScaling');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::SetTimeBasedAutoScaling - Arguments for method SetTimeBasedAutoScaling on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetTimeBasedAutoScaling on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method SetTimeBasedAutoScaling.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetTimeBasedAutoScaling.

As an example:

  $service_obj->SetTimeBasedAutoScaling(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AutoScalingSchedule => Paws::OpsWorks::WeeklyAutoScalingSchedule

  

An C<AutoScalingSchedule> with the instance schedule.










=head2 B<REQUIRED> InstanceId => Str

  

The instance ID.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetTimeBasedAutoScaling in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

