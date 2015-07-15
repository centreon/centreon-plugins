
package Paws::RDS::DBSubnetGroupMessage {
  use Moose;
  has DBSubnetGroups => (is => 'ro', isa => 'ArrayRef[Paws::RDS::DBSubnetGroup]', xmlname => 'DBSubnetGroup', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DBSubnetGroupMessage

=head1 ATTRIBUTES

=head2 DBSubnetGroups => ArrayRef[Paws::RDS::DBSubnetGroup]

  

A list of DBSubnetGroup instances.









=head2 Marker => Str

  

An optional pagination token provided by a previous request. If this
parameter is specified, the response includes only records beyond the
marker, up to the value specified by C<MaxRecords>.











=cut

