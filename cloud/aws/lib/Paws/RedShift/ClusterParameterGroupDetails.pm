
package Paws::RedShift::ClusterParameterGroupDetails {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has Parameters => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::Parameter]', xmlname => 'Parameter', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::ClusterParameterGroupDetails

=head1 ATTRIBUTES

=head2 Marker => Str

  

A value that indicates the starting point for the next set of response
records in a subsequent request. If a value is returned in a response,
you can retrieve the next set of records by providing this returned
marker value in the C<Marker> parameter and retrying the command. If
the C<Marker> field is empty, all response records have been retrieved
for the request.









=head2 Parameters => ArrayRef[Paws::RedShift::Parameter]

  

A list of Parameter instances. Each instance lists the parameters of
one cluster parameter group.











=cut

