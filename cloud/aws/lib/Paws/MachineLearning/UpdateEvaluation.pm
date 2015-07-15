
package Paws::MachineLearning::UpdateEvaluation {
  use Moose;
  has EvaluationId => (is => 'ro', isa => 'Str', required => 1);
  has EvaluationName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateEvaluation');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::MachineLearning::UpdateEvaluationOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::UpdateEvaluation - Arguments for method UpdateEvaluation on Paws::MachineLearning

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateEvaluation on the 
Amazon Machine Learning service. Use the attributes of this class
as arguments to method UpdateEvaluation.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateEvaluation.

As an example:

  $service_obj->UpdateEvaluation(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> EvaluationId => Str

  

The ID assigned to the C<Evaluation> during creation.










=head2 B<REQUIRED> EvaluationName => Str

  

A new user-supplied name or description of the C<Evaluation> that will
replace the current content.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateEvaluation in L<Paws::MachineLearning>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

