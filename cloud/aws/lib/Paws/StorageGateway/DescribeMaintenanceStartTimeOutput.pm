
package Paws::StorageGateway::DescribeMaintenanceStartTimeOutput {
  use Moose;
  has DayOfWeek => (is => 'ro', isa => 'Int');
  has GatewayARN => (is => 'ro', isa => 'Str');
  has HourOfDay => (is => 'ro', isa => 'Int');
  has MinuteOfHour => (is => 'ro', isa => 'Int');
  has Timezone => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeMaintenanceStartTimeOutput

=head1 ATTRIBUTES

=head2 DayOfWeek => Int

  
=head2 GatewayARN => Str

  
=head2 HourOfDay => Int

  
=head2 MinuteOfHour => Int

  
=head2 Timezone => Str

  


=cut

1;