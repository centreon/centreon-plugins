
package Paws::CodePipeline::PollForJobsOutput {
  use Moose;
  has jobs => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::Job]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::PollForJobsOutput

=head1 ATTRIBUTES

=head2 jobs => ArrayRef[Paws::CodePipeline::Job]

  

Information about the jobs to take action on.











=cut

1;