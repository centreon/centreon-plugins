package Paws::CodePipeline::ActionConfigurationProperty {
  use Moose;
  has description => (is => 'ro', isa => 'Str');
  has key => (is => 'ro', isa => 'Bool', required => 1);
  has name => (is => 'ro', isa => 'Str', required => 1);
  has queryable => (is => 'ro', isa => 'Bool');
  has required => (is => 'ro', isa => 'Bool', required => 1);
  has secret => (is => 'ro', isa => 'Bool', required => 1);
  has type => (is => 'ro', isa => 'Str');
}
1;
