
package Paws::Support::DescribeTrustedAdvisorCheckSummariesResponse {
  use Moose;
  has summaries => (is => 'ro', isa => 'ArrayRef[Paws::Support::TrustedAdvisorCheckSummary]', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::Support::DescribeTrustedAdvisorCheckSummariesResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> summaries => ArrayRef[Paws::Support::TrustedAdvisorCheckSummary]

  

The summary information for the requested Trusted Advisor checks.











=cut

1;