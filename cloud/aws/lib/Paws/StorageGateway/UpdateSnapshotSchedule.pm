
package Paws::StorageGateway::UpdateSnapshotSchedule {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has RecurrenceInHours => (is => 'ro', isa => 'Int', required => 1);
  has StartAt => (is => 'ro', isa => 'Int', required => 1);
  has VolumeARN => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateSnapshotSchedule');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::StorageGateway::UpdateSnapshotScheduleOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::UpdateSnapshotSchedule - Arguments for method UpdateSnapshotSchedule on Paws::StorageGateway

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateSnapshotSchedule on the 
AWS Storage Gateway service. Use the attributes of this class
as arguments to method UpdateSnapshotSchedule.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateSnapshotSchedule.

As an example:

  $service_obj->UpdateSnapshotSchedule(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Description => Str

  

Optional description of the snapshot that overwrites the existing
description.










=head2 B<REQUIRED> RecurrenceInHours => Int

  

Frequency of snapshots. Specify the number of hours between snapshots.










=head2 B<REQUIRED> StartAt => Int

  

The hour of the day at which the snapshot schedule begins represented
as I<hh>, where I<hh> is the hour (0 to 23). The hour of the day is in
the time zone of the gateway.










=head2 B<REQUIRED> VolumeARN => Str

  

The Amazon Resource Name (ARN) of the volume. Use the ListVolumes
operation to return a list of gateway volumes.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateSnapshotSchedule in L<Paws::StorageGateway>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

