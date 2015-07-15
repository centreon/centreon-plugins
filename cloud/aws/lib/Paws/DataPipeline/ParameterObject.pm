package Paws::DataPipeline::ParameterObject {
  use Moose;
  has attributes => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::ParameterAttribute]', required => 1);
  has id => (is => 'ro', isa => 'Str', required => 1);
}
1;
