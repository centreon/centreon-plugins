
package Paws::Support::DescribeCommunicationsResponse {
  use Moose;
  has communications => (is => 'ro', isa => 'ArrayRef[Paws::Support::Communication]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::Support::DescribeCommunicationsResponse

=head1 ATTRIBUTES

=head2 communications => ArrayRef[Paws::Support::Communication]

  

The communications for the case.









=head2 nextToken => Str

  

A resumption point for pagination.











=cut

1;