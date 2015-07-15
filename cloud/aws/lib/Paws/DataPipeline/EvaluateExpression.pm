
package Paws::DataPipeline::EvaluateExpression {
  use Moose;
  has expression => (is => 'ro', isa => 'Str', required => 1);
  has objectId => (is => 'ro', isa => 'Str', required => 1);
  has pipelineId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'EvaluateExpression');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DataPipeline::EvaluateExpressionOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::EvaluateExpression - Arguments for method EvaluateExpression on Paws::DataPipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method EvaluateExpression on the 
AWS Data Pipeline service. Use the attributes of this class
as arguments to method EvaluateExpression.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to EvaluateExpression.

As an example:

  $service_obj->EvaluateExpression(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> expression => Str

  

The expression to evaluate.










=head2 B<REQUIRED> objectId => Str

  

The ID of the object.










=head2 B<REQUIRED> pipelineId => Str

  

The ID of the pipeline.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method EvaluateExpression in L<Paws::DataPipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

