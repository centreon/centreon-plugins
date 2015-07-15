package Paws::Support::TrustedAdvisorCheckSummary {
  use Moose;
  has categorySpecificSummary => (is => 'ro', isa => 'Paws::Support::TrustedAdvisorCategorySpecificSummary', required => 1);
  has checkId => (is => 'ro', isa => 'Str', required => 1);
  has hasFlaggedResources => (is => 'ro', isa => 'Bool');
  has resourcesSummary => (is => 'ro', isa => 'Paws::Support::TrustedAdvisorResourcesSummary', required => 1);
  has status => (is => 'ro', isa => 'Str', required => 1);
  has timestamp => (is => 'ro', isa => 'Str', required => 1);
}
1;
