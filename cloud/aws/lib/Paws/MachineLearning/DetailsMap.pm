package Paws::MachineLearning::DetailsMap {
  use Moose;
  with 'Paws::API::MapParser';

  use MooseX::ClassAttribute;
  class_has xml_keys =>(is => 'ro', default => 'key');
  class_has xml_values =>(is => 'ro', default => 'value');

  has Algorithm => (is => 'ro', isa => 'Str');
  has PredictiveModelType => (is => 'ro', isa => 'Str');
}
1
