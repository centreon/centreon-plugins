
package Paws::DeviceFarm::ListProjectsResult {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has projects => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::Project]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::ListProjectsResult

=head1 ATTRIBUTES

=head2 nextToken => Str

  

If the number of items that are returned is significantly large, this
is an identifier that is also returned, which can be used in a
subsequent call to this operation to return the next set of items in
the list.









=head2 projects => ArrayRef[Paws::DeviceFarm::Project]

  

Information about the projects.











=cut

1;