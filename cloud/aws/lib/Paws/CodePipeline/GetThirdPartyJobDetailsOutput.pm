
package Paws::CodePipeline::GetThirdPartyJobDetailsOutput {
  use Moose;
  has jobDetails => (is => 'ro', isa => 'Paws::CodePipeline::ThirdPartyJobDetails');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::GetThirdPartyJobDetailsOutput

=head1 ATTRIBUTES

=head2 jobDetails => Paws::CodePipeline::ThirdPartyJobDetails

  

The details of the job, including any protected values defined for the
job.











=cut

1;