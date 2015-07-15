
package Paws::Support::DescribeCasesResponse {
  use Moose;
  has cases => (is => 'ro', isa => 'ArrayRef[Paws::Support::CaseDetails]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::Support::DescribeCasesResponse

=head1 ATTRIBUTES

=head2 cases => ArrayRef[Paws::Support::CaseDetails]

  

The details for the cases that match the request.









=head2 nextToken => Str

  

A resumption point for pagination.











=cut

1;