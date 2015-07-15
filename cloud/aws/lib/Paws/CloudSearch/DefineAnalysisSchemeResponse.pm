
package Paws::CloudSearch::DefineAnalysisSchemeResponse {
  use Moose;
  has AnalysisScheme => (is => 'ro', isa => 'Paws::CloudSearch::AnalysisSchemeStatus', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DefineAnalysisSchemeResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> AnalysisScheme => Paws::CloudSearch::AnalysisSchemeStatus

  


=cut

