
package Paws::CodePipeline::GetJobDetailsOutput {
  use Moose;
  has jobDetails => (is => 'ro', isa => 'Paws::CodePipeline::JobDetails');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::GetJobDetailsOutput

=head1 ATTRIBUTES

=head2 jobDetails => Paws::CodePipeline::JobDetails

  

The details of the job.

If AWSSessionCredentials is used, a long-running job can call
GetJobDetails again to obtain new credentials.











=cut

1;