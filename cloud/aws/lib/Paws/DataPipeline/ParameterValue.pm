package Paws::DataPipeline::ParameterValue {
  use Moose;
  has id => (is => 'ro', isa => 'Str', required => 1);
  has stringValue => (is => 'ro', isa => 'Str', required => 1);
}
1;
