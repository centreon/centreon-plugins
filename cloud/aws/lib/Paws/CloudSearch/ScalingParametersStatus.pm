package Paws::CloudSearch::ScalingParametersStatus {
  use Moose;
  has Options => (is => 'ro', isa => 'Paws::CloudSearch::ScalingParameters', required => 1);
  has Status => (is => 'ro', isa => 'Paws::CloudSearch::OptionStatus', required => 1);
}
1;
