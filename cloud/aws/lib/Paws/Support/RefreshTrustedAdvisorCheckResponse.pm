
package Paws::Support::RefreshTrustedAdvisorCheckResponse {
  use Moose;
  has status => (is => 'ro', isa => 'Paws::Support::TrustedAdvisorCheckRefreshStatus', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::Support::RefreshTrustedAdvisorCheckResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> status => Paws::Support::TrustedAdvisorCheckRefreshStatus

  

The current refresh status for a check, including the amount of time
until the check is eligible for refresh.











=cut

1;