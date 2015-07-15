package Paws::DataPipeline::Query {
  use Moose;
  has selectors => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::Selector]');
}
1;
