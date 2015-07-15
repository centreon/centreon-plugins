
package Paws::RedShift::ClusterSubnetGroupMessage {
  use Moose;
  has ClusterSubnetGroups => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::ClusterSubnetGroup]', xmlname => 'ClusterSubnetGroup', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::ClusterSubnetGroupMessage

=head1 ATTRIBUTES

=head2 ClusterSubnetGroups => ArrayRef[Paws::RedShift::ClusterSubnetGroup]

  

A list of ClusterSubnetGroup instances.









=head2 Marker => Str

  

A value that indicates the starting point for the next set of response
records in a subsequent request. If a value is returned in a response,
you can retrieve the next set of records by providing this returned
marker value in the C<Marker> parameter and retrying the command. If
the C<Marker> field is empty, all response records have been retrieved
for the request.











=cut

