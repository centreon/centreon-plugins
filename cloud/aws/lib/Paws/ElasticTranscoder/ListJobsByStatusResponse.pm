
package Paws::ElasticTranscoder::ListJobsByStatusResponse {
  use Moose;
  has Jobs => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::Job]');
  has NextPageToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder::ListJobsByStatusResponse

=head1 ATTRIBUTES

=head2 Jobs => ArrayRef[Paws::ElasticTranscoder::Job]

  

An array of C<Job> objects that have the specified status.









=head2 NextPageToken => Str

  

A value that you use to access the second and subsequent pages of
results, if any. When the jobs in the specified pipeline fit on one
page or when you've reached the last page of results, the value of
C<NextPageToken> is C<null>.











=cut

