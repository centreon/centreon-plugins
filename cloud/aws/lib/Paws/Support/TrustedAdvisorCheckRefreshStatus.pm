package Paws::Support::TrustedAdvisorCheckRefreshStatus {
  use Moose;
  has checkId => (is => 'ro', isa => 'Str', required => 1);
  has millisUntilNextRefreshable => (is => 'ro', isa => 'Int', required => 1);
  has status => (is => 'ro', isa => 'Str', required => 1);
}
1;
