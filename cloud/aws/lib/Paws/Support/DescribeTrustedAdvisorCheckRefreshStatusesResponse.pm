
package Paws::Support::DescribeTrustedAdvisorCheckRefreshStatusesResponse {
  use Moose;
  has statuses => (is => 'ro', isa => 'ArrayRef[Paws::Support::TrustedAdvisorCheckRefreshStatus]', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::Support::DescribeTrustedAdvisorCheckRefreshStatusesResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> statuses => ArrayRef[Paws::Support::TrustedAdvisorCheckRefreshStatus]

  

The refresh status of the specified Trusted Advisor checks.











=cut

1;