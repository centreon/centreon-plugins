
package Paws::ElasticTranscoder::ListPipelinesResponse {
  use Moose;
  has NextPageToken => (is => 'ro', isa => 'Str');
  has Pipelines => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::Pipeline]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder::ListPipelinesResponse

=head1 ATTRIBUTES

=head2 NextPageToken => Str

  

A value that you use to access the second and subsequent pages of
results, if any. When the pipelines fit on one page or when you've
reached the last page of results, the value of C<NextPageToken> is
C<null>.









=head2 Pipelines => ArrayRef[Paws::ElasticTranscoder::Pipeline]

  

An array of C<Pipeline> objects.











=cut

