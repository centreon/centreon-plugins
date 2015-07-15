
package Paws::RDS::DBSecurityGroupMessage {
  use Moose;
  has DBSecurityGroups => (is => 'ro', isa => 'ArrayRef[Paws::RDS::DBSecurityGroup]', xmlname => 'DBSecurityGroup', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DBSecurityGroupMessage

=head1 ATTRIBUTES

=head2 DBSecurityGroups => ArrayRef[Paws::RDS::DBSecurityGroup]

  

A list of DBSecurityGroup instances.









=head2 Marker => Str

  

An optional pagination token provided by a previous request. If this
parameter is specified, the response includes only records beyond the
marker, up to the value specified by C<MaxRecords>.











=cut

