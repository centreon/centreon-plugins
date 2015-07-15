package Paws::DataPipeline::Field {
  use Moose;
  has key => (is => 'ro', isa => 'Str', required => 1);
  has refValue => (is => 'ro', isa => 'Str');
  has stringValue => (is => 'ro', isa => 'Str');
}
1;
