package Paws::Support::TrustedAdvisorCategorySpecificSummary {
  use Moose;
  has costOptimizing => (is => 'ro', isa => 'Paws::Support::TrustedAdvisorCostOptimizingSummary');
}
1;
