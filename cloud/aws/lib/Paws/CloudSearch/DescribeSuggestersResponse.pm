
package Paws::CloudSearch::DescribeSuggestersResponse {
  use Moose;
  has Suggesters => (is => 'ro', isa => 'ArrayRef[Paws::CloudSearch::SuggesterStatus]', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DescribeSuggestersResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Suggesters => ArrayRef[Paws::CloudSearch::SuggesterStatus]

  

The suggesters configured for the domain specified in the request.











=cut

