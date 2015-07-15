
package Paws::CloudHSM::ListHsmsResponse {
  use Moose;
  has HsmList => (is => 'ro', isa => 'ArrayRef[Str]');
  has NextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudHSM::ListHsmsResponse

=head1 ATTRIBUTES

=head2 HsmList => ArrayRef[Str]

  

The list of ARNs that identify the HSMs.









=head2 NextToken => Str

  

If not null, more results are available. Pass this value to ListHsms to
retrieve the next set of items.











=cut

1;