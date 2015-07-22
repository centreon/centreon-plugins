
package Paws::CodePipeline::DisableStageTransition {
  use Moose;
  has pipelineName => (is => 'ro', isa => 'Str', required => 1);
  has reason => (is => 'ro', isa => 'Str', required => 1);
  has stageName => (is => 'ro', isa => 'Str', required => 1);
  has transitionType => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DisableStageTransition');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::DisableStageTransition - Arguments for method DisableStageTransition on Paws::CodePipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method DisableStageTransition on the 
AWS CodePipeline service. Use the attributes of this class
as arguments to method DisableStageTransition.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DisableStageTransition.

As an example:

  $service_obj->DisableStageTransition(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> pipelineName => Str

  

The name of the pipeline in which you want to disable the flow of
artifacts from one stage to another.










=head2 B<REQUIRED> reason => Str

  

The reason given to the user why a stage is disabled, such as waiting
for manual approval or manual tests. This message is displayed in the
pipeline console UI.










=head2 B<REQUIRED> stageName => Str

  

The name of the stage where you want to disable the inbound or outbound
transition of artifacts.










=head2 B<REQUIRED> transitionType => Str

  

Specifies whether artifacts will be prevented from transitioning into
the stage and being processed by the actions in that stage (inbound),
or prevented from transitioning from the stage after they have been
processed by the actions in that stage (outbound).












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DisableStageTransition in L<Paws::CodePipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

