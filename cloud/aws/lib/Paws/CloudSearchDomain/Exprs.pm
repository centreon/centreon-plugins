package Paws::CloudSearchDomain::Exprs {
  use Moose;
  with 'Paws::API::StrToNativeMapParser';

  use MooseX::ClassAttribute;
  class_has xml_keys =>(is => 'ro', default => 'key');
  class_has xml_values =>(is => 'ro', default => 'value');

  has Map => (is => 'ro', isa => 'HashRef[Str]');
}
1
