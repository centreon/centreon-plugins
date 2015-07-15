package Paws::DataPipeline::Selector {
  use Moose;
  has fieldName => (is => 'ro', isa => 'Str');
  has operator => (is => 'ro', isa => 'Paws::DataPipeline::Operator');
}
1;
