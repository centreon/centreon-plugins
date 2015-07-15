
package Paws::CloudSearch::DeleteAnalysisSchemeResponse {
  use Moose;
  has AnalysisScheme => (is => 'ro', isa => 'Paws::CloudSearch::AnalysisSchemeStatus', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DeleteAnalysisSchemeResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> AnalysisScheme => Paws::CloudSearch::AnalysisSchemeStatus

  

The status of the analysis scheme being deleted.











=cut

