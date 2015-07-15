
package Paws::DataPipeline::CreatePipeline {
  use Moose;
  has description => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str', required => 1);
  has tags => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::Tag]');
  has uniqueId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreatePipeline');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DataPipeline::CreatePipelineOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::CreatePipeline - Arguments for method CreatePipeline on Paws::DataPipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreatePipeline on the 
AWS Data Pipeline service. Use the attributes of this class
as arguments to method CreatePipeline.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreatePipeline.

As an example:

  $service_obj->CreatePipeline(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 description => Str

  

The description for the pipeline.










=head2 B<REQUIRED> name => Str

  

The name for the pipeline. You can use the same name for multiple
pipelines associated with your AWS account, because AWS Data Pipeline
assigns each pipeline a unique pipeline identifier.










=head2 tags => ArrayRef[Paws::DataPipeline::Tag]

  

A list of tags to associate with the pipeline at creation. Tags let you
control access to pipelines. For more information, see Controlling User
Access to Pipelines in the I<AWS Data Pipeline Developer Guide>.










=head2 B<REQUIRED> uniqueId => Str

  

A unique identifier. This identifier is not the same as the pipeline
identifier assigned by AWS Data Pipeline. You are responsible for
defining the format and ensuring the uniqueness of this identifier. You
use this parameter to ensure idempotency during repeated calls to
C<CreatePipeline>. For example, if the first call to C<CreatePipeline>
does not succeed, you can pass in the same unique identifier and
pipeline name combination on a subsequent call to C<CreatePipeline>.
C<CreatePipeline> ensures that if a pipeline already exists with the
same name and unique identifier, a new pipeline is not created.
Instead, you'll receive the pipeline identifier from the previous
attempt. The uniqueness of the name and unique identifier combination
is scoped to the AWS account or IAM user credentials.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreatePipeline in L<Paws::DataPipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

