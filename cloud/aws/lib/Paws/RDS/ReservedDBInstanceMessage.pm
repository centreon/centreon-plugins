
package Paws::RDS::ReservedDBInstanceMessage {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has ReservedDBInstances => (is => 'ro', isa => 'ArrayRef[Paws::RDS::ReservedDBInstance]', xmlname => 'ReservedDBInstance', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::ReservedDBInstanceMessage

=head1 ATTRIBUTES

=head2 Marker => Str

  

An optional pagination token provided by a previous request. If this
parameter is specified, the response includes only records beyond the
marker, up to the value specified by C<MaxRecords>.









=head2 ReservedDBInstances => ArrayRef[Paws::RDS::ReservedDBInstance]

  

A list of reserved DB instances.











=cut

