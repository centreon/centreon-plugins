
package Paws::DataPipeline::DescribeObjects {
  use Moose;
  has evaluateExpressions => (is => 'ro', isa => 'Bool');
  has marker => (is => 'ro', isa => 'Str');
  has objectIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has pipelineId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeObjects');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DataPipeline::DescribeObjectsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::DescribeObjects - Arguments for method DescribeObjects on Paws::DataPipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeObjects on the 
AWS Data Pipeline service. Use the attributes of this class
as arguments to method DescribeObjects.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeObjects.

As an example:

  $service_obj->DescribeObjects(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 evaluateExpressions => Bool

  

Indicates whether any expressions in the object should be evaluated
when the object descriptions are returned.










=head2 marker => Str

  

The starting point for the results to be returned. For the first call,
this value should be empty. As long as there are more results, continue
to call C<DescribeObjects> with the marker value from the previous call
to retrieve the next set of results.










=head2 B<REQUIRED> objectIds => ArrayRef[Str]

  

The IDs of the pipeline objects that contain the definitions to be
described. You can pass as many as 25 identifiers in a single call to
C<DescribeObjects>.










=head2 B<REQUIRED> pipelineId => Str

  

The ID of the pipeline that contains the object definitions.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeObjects in L<Paws::DataPipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

