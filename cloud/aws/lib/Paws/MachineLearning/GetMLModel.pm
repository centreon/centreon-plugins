
package Paws::MachineLearning::GetMLModel {
  use Moose;
  has MLModelId => (is => 'ro', isa => 'Str', required => 1);
  has Verbose => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetMLModel');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::MachineLearning::GetMLModelOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::GetMLModel - Arguments for method GetMLModel on Paws::MachineLearning

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetMLModel on the 
Amazon Machine Learning service. Use the attributes of this class
as arguments to method GetMLModel.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetMLModel.

As an example:

  $service_obj->GetMLModel(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> MLModelId => Str

  

The ID assigned to the C<MLModel> at creation.










=head2 Verbose => Bool

  

Specifies whether the C<GetMLModel> operation should return C<Recipe>.

If true, C<Recipe> is returned.

If false, C<Recipe> is not returned.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetMLModel in L<Paws::MachineLearning>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

