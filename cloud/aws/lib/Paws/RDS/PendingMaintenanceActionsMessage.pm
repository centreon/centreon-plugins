
package Paws::RDS::PendingMaintenanceActionsMessage {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has PendingMaintenanceActions => (is => 'ro', isa => 'ArrayRef[Paws::RDS::ResourcePendingMaintenanceActions]', xmlname => 'ResourcePendingMaintenanceActions', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::PendingMaintenanceActionsMessage

=head1 ATTRIBUTES

=head2 Marker => Str

  

An optional pagination token provided by a previous
C<DescribePendingMaintenanceActions> request. If this parameter is
specified, the response includes only records beyond the marker, up to
a number of records specified by C<MaxRecords>.









=head2 PendingMaintenanceActions => ArrayRef[Paws::RDS::ResourcePendingMaintenanceActions]

  

A list of the pending maintenance actions for the resource.











=cut

