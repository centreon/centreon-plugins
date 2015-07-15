package Paws::DataPipeline::ValidationError {
  use Moose;
  has errors => (is => 'ro', isa => 'ArrayRef[Str]');
  has id => (is => 'ro', isa => 'Str');
}
1;
