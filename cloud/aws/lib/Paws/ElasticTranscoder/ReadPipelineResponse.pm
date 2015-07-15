
package Paws::ElasticTranscoder::ReadPipelineResponse {
  use Moose;
  has Pipeline => (is => 'ro', isa => 'Paws::ElasticTranscoder::Pipeline');
  has Warnings => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::Warning]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder::ReadPipelineResponse

=head1 ATTRIBUTES

=head2 Pipeline => Paws::ElasticTranscoder::Pipeline

  

A section of the response body that provides information about the
pipeline.









=head2 Warnings => ArrayRef[Paws::ElasticTranscoder::Warning]

  

Elastic Transcoder returns a warning if the resources used by your
pipeline are not in the same region as the pipeline.

Using resources in the same region, such as your Amazon S3 buckets,
Amazon SNS notification topics, and AWS KMS key, reduces processing
time and prevents cross-regional charges.











=cut

