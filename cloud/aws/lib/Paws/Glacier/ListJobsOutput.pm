
package Paws::Glacier::ListJobsOutput {
  use Moose;
  has JobList => (is => 'ro', isa => 'ArrayRef[Paws::Glacier::GlacierJobDescription]');
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier::ListJobsOutput

=head1 ATTRIBUTES

=head2 JobList => ArrayRef[Paws::Glacier::GlacierJobDescription]

  

A list of job objects. Each job object contains metadata describing the
job.









=head2 Marker => Str

  

An opaque string that represents where to continue pagination of the
results. You use this value in a new List Jobs request to obtain more
jobs in the list. If there are no more jobs, this value is C<null>.











=cut

