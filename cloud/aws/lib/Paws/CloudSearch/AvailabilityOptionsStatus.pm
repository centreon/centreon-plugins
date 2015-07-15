package Paws::CloudSearch::AvailabilityOptionsStatus {
  use Moose;
  has Options => (is => 'ro', isa => 'Bool', required => 1);
  has Status => (is => 'ro', isa => 'Paws::CloudSearch::OptionStatus', required => 1);
}
1;
