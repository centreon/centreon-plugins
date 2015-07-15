
package Paws::RDS::DBInstanceMessage {
  use Moose;
  has DBInstances => (is => 'ro', isa => 'ArrayRef[Paws::RDS::DBInstance]', xmlname => 'DBInstance', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DBInstanceMessage

=head1 ATTRIBUTES

=head2 DBInstances => ArrayRef[Paws::RDS::DBInstance]

  

A list of DBInstance instances.









=head2 Marker => Str

  

An optional pagination token provided by a previous request. If this
parameter is specified, the response includes only records beyond the
marker, up to the value specified by C<MaxRecords> .











=cut

