
package Paws::CodePipeline::PutActionRevision {
  use Moose;
  has actionName => (is => 'ro', isa => 'Str', required => 1);
  has actionRevision => (is => 'ro', isa => 'Paws::CodePipeline::ActionRevision', required => 1);
  has pipelineName => (is => 'ro', isa => 'Str', required => 1);
  has stageName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutActionRevision');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodePipeline::PutActionRevisionOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::PutActionRevision - Arguments for method PutActionRevision on Paws::CodePipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutActionRevision on the 
AWS CodePipeline service. Use the attributes of this class
as arguments to method PutActionRevision.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutActionRevision.

As an example:

  $service_obj->PutActionRevision(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> actionName => Str

  

The name of the action that will process the revision.










=head2 B<REQUIRED> actionRevision => Paws::CodePipeline::ActionRevision

  

=head2 B<REQUIRED> pipelineName => Str

  

The name of the pipeline that will start processing the revision to the
source.










=head2 B<REQUIRED> stageName => Str

  

The name of the stage that contains the action that will act upon the
revision.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutActionRevision in L<Paws::CodePipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

