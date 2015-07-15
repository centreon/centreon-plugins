package Paws::DataPipeline::Operator {
  use Moose;
  has type => (is => 'ro', isa => 'Str');
  has values => (is => 'ro', isa => 'ArrayRef[Str]');
}
1;
