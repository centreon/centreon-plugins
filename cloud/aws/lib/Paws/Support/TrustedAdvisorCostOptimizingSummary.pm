package Paws::Support::TrustedAdvisorCostOptimizingSummary {
  use Moose;
  has estimatedMonthlySavings => (is => 'ro', isa => 'Num', required => 1);
  has estimatedPercentMonthlySavings => (is => 'ro', isa => 'Num', required => 1);
}
1;
