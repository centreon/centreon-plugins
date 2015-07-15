
package Paws::CloudSearch::DeleteSuggesterResponse {
  use Moose;
  has Suggester => (is => 'ro', isa => 'Paws::CloudSearch::SuggesterStatus', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DeleteSuggesterResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Suggester => Paws::CloudSearch::SuggesterStatus

  

The status of the suggester being deleted.











=cut

