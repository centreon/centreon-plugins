
package Paws::DeviceFarm::ListJobsResult {
  use Moose;
  has jobs => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::Job]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::ListJobsResult

=head1 ATTRIBUTES

=head2 jobs => ArrayRef[Paws::DeviceFarm::Job]

  

Information about the jobs.









=head2 nextToken => Str

  

If the number of items that are returned is significantly large, this
is an identifier that is also returned, which can be used in a
subsequent call to this operation to return the next set of items in
the list.











=cut

1;