package Paws::DataPipeline::InstanceIdentity {
  use Moose;
  has document => (is => 'ro', isa => 'Str');
  has signature => (is => 'ro', isa => 'Str');
}
1;
