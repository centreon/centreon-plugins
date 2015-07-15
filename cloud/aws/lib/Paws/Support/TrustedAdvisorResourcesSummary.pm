package Paws::Support::TrustedAdvisorResourcesSummary {
  use Moose;
  has resourcesFlagged => (is => 'ro', isa => 'Int', required => 1);
  has resourcesIgnored => (is => 'ro', isa => 'Int', required => 1);
  has resourcesProcessed => (is => 'ro', isa => 'Int', required => 1);
  has resourcesSuppressed => (is => 'ro', isa => 'Int', required => 1);
}
1;
