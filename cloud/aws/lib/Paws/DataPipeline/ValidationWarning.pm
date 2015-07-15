package Paws::DataPipeline::ValidationWarning {
  use Moose;
  has id => (is => 'ro', isa => 'Str');
  has warnings => (is => 'ro', isa => 'ArrayRef[Str]');
}
1;
