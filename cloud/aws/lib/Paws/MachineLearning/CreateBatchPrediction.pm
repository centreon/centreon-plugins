
package Paws::MachineLearning::CreateBatchPrediction {
  use Moose;
  has BatchPredictionDataSourceId => (is => 'ro', isa => 'Str', required => 1);
  has BatchPredictionId => (is => 'ro', isa => 'Str', required => 1);
  has BatchPredictionName => (is => 'ro', isa => 'Str');
  has MLModelId => (is => 'ro', isa => 'Str', required => 1);
  has OutputUri => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateBatchPrediction');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::MachineLearning::CreateBatchPredictionOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::CreateBatchPrediction - Arguments for method CreateBatchPrediction on Paws::MachineLearning

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateBatchPrediction on the 
Amazon Machine Learning service. Use the attributes of this class
as arguments to method CreateBatchPrediction.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateBatchPrediction.

As an example:

  $service_obj->CreateBatchPrediction(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> BatchPredictionDataSourceId => Str

  

The ID of the C<DataSource> that points to the group of observations to
predict.










=head2 B<REQUIRED> BatchPredictionId => Str

  

A user-supplied ID that uniquely identifies the C<BatchPrediction>.










=head2 BatchPredictionName => Str

  

A user-supplied name or description of the C<BatchPrediction>.
C<BatchPredictionName> can only use the UTF-8 character set.










=head2 B<REQUIRED> MLModelId => Str

  

The ID of the C<MLModel> that will generate predictions for the group
of observations.










=head2 B<REQUIRED> OutputUri => Str

  

The location of an Amazon Simple Storage Service (Amazon S3) bucket or
directory to store the batch prediction results. The following
substrings are not allowed in the s3 key portion of the "outputURI"
field: ':', '//', '/./', '/../'.

Amazon ML needs permissions to store and retrieve the logs on your
behalf. For information about how to set permissions, see the Amazon
Machine Learning Developer Guide.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateBatchPrediction in L<Paws::MachineLearning>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

