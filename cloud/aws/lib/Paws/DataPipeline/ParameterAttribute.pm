package Paws::DataPipeline::ParameterAttribute {
  use Moose;
  has key => (is => 'ro', isa => 'Str', required => 1);
  has stringValue => (is => 'ro', isa => 'Str', required => 1);
}
1;
