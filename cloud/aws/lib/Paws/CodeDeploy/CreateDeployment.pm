
package Paws::CodeDeploy::CreateDeployment {
  use Moose;
  has applicationName => (is => 'ro', isa => 'Str', required => 1);
  has deploymentConfigName => (is => 'ro', isa => 'Str');
  has deploymentGroupName => (is => 'ro', isa => 'Str');
  has description => (is => 'ro', isa => 'Str');
  has ignoreApplicationStopFailures => (is => 'ro', isa => 'Bool');
  has revision => (is => 'ro', isa => 'Paws::CodeDeploy::RevisionLocation');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateDeployment');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodeDeploy::CreateDeploymentOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::CreateDeployment - Arguments for method CreateDeployment on Paws::CodeDeploy

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateDeployment on the 
AWS CodeDeploy service. Use the attributes of this class
as arguments to method CreateDeployment.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateDeployment.

As an example:

  $service_obj->CreateDeployment(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> applicationName => Str

  

The name of an existing AWS CodeDeploy application associated with the
applicable IAM user or AWS account.










=head2 deploymentConfigName => Str

  

The name of an existing deployment configuration associated with the
applicable IAM user or AWS account.

If not specified, the value configured in the deployment group will be
used as the default. If the deployment group does not have a deployment
configuration associated with it, then CodeDeployDefault.OneAtATime
will be used by default.










=head2 deploymentGroupName => Str

  

The deployment group's name.










=head2 description => Str

  

A comment about the deployment.










=head2 ignoreApplicationStopFailures => Bool

  

If set to true, then if the deployment causes the ApplicationStop
deployment lifecycle event to fail to a specific instance, the
deployment will not be considered to have failed to that instance at
that point and will continue on to the BeforeInstall deployment
lifecycle event.

If set to false or not specified, then if the deployment causes the
ApplicationStop deployment lifecycle event to fail to a specific
instance, the deployment will stop to that instance, and the deployment
to that instance will be considered to have failed.










=head2 revision => Paws::CodeDeploy::RevisionLocation

  

The type of revision to deploy, along with information about the
revision's location.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateDeployment in L<Paws::CodeDeploy>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

