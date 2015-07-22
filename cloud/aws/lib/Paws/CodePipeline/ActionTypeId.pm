package Paws::CodePipeline::ActionTypeId {
  use Moose;
  has category => (is => 'ro', isa => 'Str', required => 1);
  has owner => (is => 'ro', isa => 'Str', required => 1);
  has provider => (is => 'ro', isa => 'Str', required => 1);
  has version => (is => 'ro', isa => 'Str', required => 1);
}
1;
