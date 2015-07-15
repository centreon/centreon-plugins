
package Paws::Support::DescribeTrustedAdvisorChecksResponse {
  use Moose;
  has checks => (is => 'ro', isa => 'ArrayRef[Paws::Support::TrustedAdvisorCheckDescription]', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::Support::DescribeTrustedAdvisorChecksResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> checks => ArrayRef[Paws::Support::TrustedAdvisorCheckDescription]

  

Information about all available Trusted Advisor checks.











=cut

1;