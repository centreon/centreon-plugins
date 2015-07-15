
package Paws::RDS::DBParameterGroupsMessage {
  use Moose;
  has DBParameterGroups => (is => 'ro', isa => 'ArrayRef[Paws::RDS::DBParameterGroup]', xmlname => 'DBParameterGroup', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DBParameterGroupsMessage

=head1 ATTRIBUTES

=head2 DBParameterGroups => ArrayRef[Paws::RDS::DBParameterGroup]

  

A list of DBParameterGroup instances.









=head2 Marker => Str

  

An optional pagination token provided by a previous request. If this
parameter is specified, the response includes only records beyond the
marker, up to the value specified by C<MaxRecords>.











=cut

