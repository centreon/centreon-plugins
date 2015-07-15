
package Paws::CloudSearch::DefineSuggesterResponse {
  use Moose;
  has Suggester => (is => 'ro', isa => 'Paws::CloudSearch::SuggesterStatus', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DefineSuggesterResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Suggester => Paws::CloudSearch::SuggesterStatus

  


=cut

