
package Paws::CloudSearch::DescribeAnalysisSchemesResponse {
  use Moose;
  has AnalysisSchemes => (is => 'ro', isa => 'ArrayRef[Paws::CloudSearch::AnalysisSchemeStatus]', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DescribeAnalysisSchemesResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> AnalysisSchemes => ArrayRef[Paws::CloudSearch::AnalysisSchemeStatus]

  

The analysis scheme descriptions.











=cut

