
package Paws::StorageGateway::UpdateMaintenanceStartTime {
  use Moose;
  has DayOfWeek => (is => 'ro', isa => 'Int', required => 1);
  has GatewayARN => (is => 'ro', isa => 'Str', required => 1);
  has HourOfDay => (is => 'ro', isa => 'Int', required => 1);
  has MinuteOfHour => (is => 'ro', isa => 'Int', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateMaintenanceStartTime');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::StorageGateway::UpdateMaintenanceStartTimeOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::UpdateMaintenanceStartTime - Arguments for method UpdateMaintenanceStartTime on Paws::StorageGateway

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateMaintenanceStartTime on the 
AWS Storage Gateway service. Use the attributes of this class
as arguments to method UpdateMaintenanceStartTime.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateMaintenanceStartTime.

As an example:

  $service_obj->UpdateMaintenanceStartTime(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DayOfWeek => Int

  

The maintenance start time day of the week.










=head2 B<REQUIRED> GatewayARN => Str

  

=head2 B<REQUIRED> HourOfDay => Int

  

The hour component of the maintenance start time represented as hh,
where I<hh> is the hour (00 to 23). The hour of the day is in the time
zone of the gateway.










=head2 B<REQUIRED> MinuteOfHour => Int

  

The minute component of the maintenance start time represented as
I<mm>, where I<mm> is the minute (00 to 59). The minute of the hour is
in the time zone of the gateway.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateMaintenanceStartTime in L<Paws::StorageGateway>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

