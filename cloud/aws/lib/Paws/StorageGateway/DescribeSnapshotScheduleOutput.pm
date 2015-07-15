
package Paws::StorageGateway::DescribeSnapshotScheduleOutput {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has RecurrenceInHours => (is => 'ro', isa => 'Int');
  has StartAt => (is => 'ro', isa => 'Int');
  has Timezone => (is => 'ro', isa => 'Str');
  has VolumeARN => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeSnapshotScheduleOutput

=head1 ATTRIBUTES

=head2 Description => Str

  
=head2 RecurrenceInHours => Int

  
=head2 StartAt => Int

  
=head2 Timezone => Str

  
=head2 VolumeARN => Str

  


=cut

1;