
package Paws::CodePipeline::PollForThirdPartyJobsOutput {
  use Moose;
  has jobs => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::ThirdPartyJob]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::PollForThirdPartyJobsOutput

=head1 ATTRIBUTES

=head2 jobs => ArrayRef[Paws::CodePipeline::ThirdPartyJob]

  

Information about the jobs to take action on.











=cut

1;