package Paws::CloudWatch::StatisticSet {
  use Moose;
  has Maximum => (is => 'ro', isa => 'Num', required => 1);
  has Minimum => (is => 'ro', isa => 'Num', required => 1);
  has SampleCount => (is => 'ro', isa => 'Num', required => 1);
  has Sum => (is => 'ro', isa => 'Num', required => 1);
}
1;
