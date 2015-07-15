
package Paws::MachineLearning::DeleteMLModel {
  use Moose;
  has MLModelId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteMLModel');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::MachineLearning::DeleteMLModelOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::DeleteMLModel - Arguments for method DeleteMLModel on Paws::MachineLearning

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteMLModel on the 
Amazon Machine Learning service. Use the attributes of this class
as arguments to method DeleteMLModel.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteMLModel.

As an example:

  $service_obj->DeleteMLModel(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> MLModelId => Str

  

A user-supplied ID that uniquely identifies the C<MLModel>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteMLModel in L<Paws::MachineLearning>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

