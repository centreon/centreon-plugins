
package Paws::RDS::DBSnapshotMessage {
  use Moose;
  has DBSnapshots => (is => 'ro', isa => 'ArrayRef[Paws::RDS::DBSnapshot]', xmlname => 'DBSnapshot', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DBSnapshotMessage

=head1 ATTRIBUTES

=head2 DBSnapshots => ArrayRef[Paws::RDS::DBSnapshot]

  

A list of DBSnapshot instances.









=head2 Marker => Str

  

An optional pagination token provided by a previous request. If this
parameter is specified, the response includes only records beyond the
marker, up to the value specified by C<MaxRecords>.











=cut

