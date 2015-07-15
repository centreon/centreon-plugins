
package Paws::Glacier::InitiateJobOutput {
  use Moose;
  has jobId => (is => 'ro', isa => 'Str');
  has location => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier::InitiateJobOutput

=head1 ATTRIBUTES

=head2 jobId => Str

  

The ID of the job.









=head2 location => Str

  

The relative URI path of the job.











=cut

