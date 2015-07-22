
package Paws::CodePipeline::CreateCustomActionType {
  use Moose;
  has category => (is => 'ro', isa => 'Str', required => 1);
  has configurationProperties => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::ActionConfigurationProperty]');
  has inputArtifactDetails => (is => 'ro', isa => 'Paws::CodePipeline::ArtifactDetails', required => 1);
  has outputArtifactDetails => (is => 'ro', isa => 'Paws::CodePipeline::ArtifactDetails', required => 1);
  has provider => (is => 'ro', isa => 'Str', required => 1);
  has settings => (is => 'ro', isa => 'Paws::CodePipeline::ActionTypeSettings');
  has version => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateCustomActionType');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodePipeline::CreateCustomActionTypeOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::CreateCustomActionType - Arguments for method CreateCustomActionType on Paws::CodePipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateCustomActionType on the 
AWS CodePipeline service. Use the attributes of this class
as arguments to method CreateCustomActionType.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateCustomActionType.

As an example:

  $service_obj->CreateCustomActionType(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> category => Str

  

The category of the custom action, such as a source action or a build
action.










=head2 configurationProperties => ArrayRef[Paws::CodePipeline::ActionConfigurationProperty]

  

The configuration properties for the custom action.










=head2 B<REQUIRED> inputArtifactDetails => Paws::CodePipeline::ArtifactDetails

  

=head2 B<REQUIRED> outputArtifactDetails => Paws::CodePipeline::ArtifactDetails

  

=head2 B<REQUIRED> provider => Str

  

The provider of the service used in the custom action, such as AWS
CodeDeploy.










=head2 settings => Paws::CodePipeline::ActionTypeSettings

  

=head2 B<REQUIRED> version => Str

  

The version number of the custom action.

A newly-created custom action is always assigned a version number of
C<1>. This is required.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateCustomActionType in L<Paws::CodePipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

