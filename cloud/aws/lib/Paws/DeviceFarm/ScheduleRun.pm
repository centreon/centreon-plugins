
package Paws::DeviceFarm::ScheduleRun {
  use Moose;
  has appArn => (is => 'ro', isa => 'Str', required => 1);
  has configuration => (is => 'ro', isa => 'Paws::DeviceFarm::ScheduleRunConfiguration');
  has devicePoolArn => (is => 'ro', isa => 'Str', required => 1);
  has name => (is => 'ro', isa => 'Str');
  has projectArn => (is => 'ro', isa => 'Str', required => 1);
  has test => (is => 'ro', isa => 'Paws::DeviceFarm::ScheduleRunTest', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ScheduleRun');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DeviceFarm::ScheduleRunResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::ScheduleRun - Arguments for method ScheduleRun on Paws::DeviceFarm

=head1 DESCRIPTION

This class represents the parameters used for calling the method ScheduleRun on the 
AWS Device Farm service. Use the attributes of this class
as arguments to method ScheduleRun.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ScheduleRun.

As an example:

  $service_obj->ScheduleRun(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> appArn => Str

  

The ARN of the app to schedule a run.










=head2 configuration => Paws::DeviceFarm::ScheduleRunConfiguration

  

Information about the settings for the run to be scheduled.










=head2 B<REQUIRED> devicePoolArn => Str

  

The ARN of the device pool for the run to be scheduled.










=head2 name => Str

  

The name for the run to be scheduled.










=head2 B<REQUIRED> projectArn => Str

  

The ARN of the project for the run to be scheduled.










=head2 B<REQUIRED> test => Paws::DeviceFarm::ScheduleRunTest

  

Information about the test for the run to be scheduled.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ScheduleRun in L<Paws::DeviceFarm>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

