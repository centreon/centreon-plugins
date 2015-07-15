
package Paws::MachineLearning::CreateEvaluation {
  use Moose;
  has EvaluationDataSourceId => (is => 'ro', isa => 'Str', required => 1);
  has EvaluationId => (is => 'ro', isa => 'Str', required => 1);
  has EvaluationName => (is => 'ro', isa => 'Str');
  has MLModelId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateEvaluation');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::MachineLearning::CreateEvaluationOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::CreateEvaluation - Arguments for method CreateEvaluation on Paws::MachineLearning

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateEvaluation on the 
Amazon Machine Learning service. Use the attributes of this class
as arguments to method CreateEvaluation.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateEvaluation.

As an example:

  $service_obj->CreateEvaluation(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> EvaluationDataSourceId => Str

  

The ID of the C<DataSource> for the evaluation. The schema of the
C<DataSource> must match the schema used to create the C<MLModel>.










=head2 B<REQUIRED> EvaluationId => Str

  

A user-supplied ID that uniquely identifies the C<Evaluation>.










=head2 EvaluationName => Str

  

A user-supplied name or description of the C<Evaluation>.










=head2 B<REQUIRED> MLModelId => Str

  

The ID of the C<MLModel> to evaluate.

The schema used in creating the C<MLModel> must match the schema of the
C<DataSource> used in the C<Evaluation>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateEvaluation in L<Paws::MachineLearning>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

