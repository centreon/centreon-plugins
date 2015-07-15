
package Paws::ElasticTranscoder::TestRoleResponse {
  use Moose;
  has Messages => (is => 'ro', isa => 'ArrayRef[Str]');
  has Success => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder::TestRoleResponse

=head1 ATTRIBUTES

=head2 Messages => ArrayRef[Str]

  

If the C<Success> element contains C<false>, this value is an array of
one or more error messages that were generated during the test process.









=head2 Success => Str

  

If the operation is successful, this value is C<true>; otherwise, the
value is C<false>.











=cut

