
package Paws::Support::ResolveCaseResponse {
  use Moose;
  has finalCaseStatus => (is => 'ro', isa => 'Str');
  has initialCaseStatus => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::Support::ResolveCaseResponse

=head1 ATTRIBUTES

=head2 finalCaseStatus => Str

  

The status of the case after the ResolveCase request was processed.









=head2 initialCaseStatus => Str

  

The status of the case when the ResolveCase request was sent.











=cut

1;