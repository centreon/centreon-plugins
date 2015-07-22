package Paws::OpsWorks {
  use Moose;
  sub service { 'opsworks' }
  sub version { '2013-02-18' }
  sub target_prefix { 'OpsWorks_20130218' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub AssignInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::AssignInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AssignVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::AssignVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AssociateElasticIp {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::AssociateElasticIp', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AttachElasticLoadBalancer {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::AttachElasticLoadBalancer', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CloneStack {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::CloneStack', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateApp {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::CreateApp', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDeployment {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::CreateDeployment', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::CreateInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateLayer {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::CreateLayer', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateStack {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::CreateStack', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateUserProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::CreateUserProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteApp {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DeleteApp', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DeleteInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteLayer {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DeleteLayer', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteStack {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DeleteStack', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteUserProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DeleteUserProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeregisterElasticIp {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DeregisterElasticIp', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeregisterInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DeregisterInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeregisterRdsDbInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DeregisterRdsDbInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeregisterVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DeregisterVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeAgentVersions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeAgentVersions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeApps {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeApps', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeCommands {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeCommands', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDeployments {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeDeployments', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeElasticIps {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeElasticIps', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeElasticLoadBalancers {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeElasticLoadBalancers', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeLayers {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeLayers', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeLoadBasedAutoScaling {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeLoadBasedAutoScaling', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeMyUserProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeMyUserProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribePermissions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribePermissions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeRaidArrays {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeRaidArrays', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeRdsDbInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeRdsDbInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeServiceErrors {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeServiceErrors', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeStackProvisioningParameters {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeStackProvisioningParameters', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeStacks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeStacks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeStackSummary {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeStackSummary', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeTimeBasedAutoScaling {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeTimeBasedAutoScaling', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeUserProfiles {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeUserProfiles', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVolumes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DescribeVolumes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DetachElasticLoadBalancer {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DetachElasticLoadBalancer', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DisassociateElasticIp {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::DisassociateElasticIp', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetHostnameSuggestion {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::GetHostnameSuggestion', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GrantAccess {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::GrantAccess', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RebootInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::RebootInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RegisterElasticIp {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::RegisterElasticIp', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RegisterInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::RegisterInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RegisterRdsDbInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::RegisterRdsDbInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RegisterVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::RegisterVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetLoadBasedAutoScaling {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::SetLoadBasedAutoScaling', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetPermission {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::SetPermission', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetTimeBasedAutoScaling {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::SetTimeBasedAutoScaling', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StartInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::StartInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StartStack {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::StartStack', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StopInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::StopInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StopStack {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::StopStack', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UnassignInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::UnassignInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UnassignVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::UnassignVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateApp {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::UpdateApp', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateElasticIp {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::UpdateElasticIp', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::UpdateInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateLayer {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::UpdateLayer', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateMyUserProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::UpdateMyUserProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateRdsDbInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::UpdateRdsDbInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateStack {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::UpdateStack', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateUserProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::UpdateUserProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::OpsWorks::UpdateVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks - Perl Interface to AWS AWS OpsWorks

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('OpsWorks')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



AWS OpsWorks

Welcome to the I<AWS OpsWorks API Reference>. This guide provides
descriptions, syntax, and usage examples about AWS OpsWorks actions and
data types, including common parameters and error codes.

AWS OpsWorks is an application management service that provides an
integrated experience for overseeing the complete application
lifecycle. For information about this product, go to the AWS OpsWorks
details page.

B<SDKs and CLI>

The most common way to use the AWS OpsWorks API is by using the AWS
Command Line Interface (CLI) or by using one of the AWS SDKs to
implement applications in your preferred language. For more
information, see:

=over

=item * AWS CLI

=item * AWS SDK for Java

=item * AWS SDK for .NET

=item * AWS SDK for PHP 2

=item * AWS SDK for Ruby

=item * AWS SDK for Node.js

=item * AWS SDK for Python(Boto)

=back

B<Endpoints>

AWS OpsWorks supports only one endpoint,
opsworks.us-east-1.amazonaws.com (HTTPS), so you must connect to that
endpoint. You can then use the API to direct AWS OpsWorks to create
stacks in any AWS Region.

B<Chef Versions>

When you call CreateStack, CloneStack, or UpdateStack we recommend you
use the C<ConfigurationManager> parameter to specify the Chef version,
0.9, 11.4, or 11.10. The default value is currently 11.10. For more
information, see Chef Versions.

You can still specify Chef 0.9 for your stack, but new features are not
available for Chef 0.9 stacks, and support is scheduled to end on July
24, 2014. We do not recommend using Chef 0.9 for new stacks, and we
recommend migrating your existing Chef 0.9 stacks to Chef 11.10 as soon
as possible.










=head1 METHODS

=head2 AssignInstance(InstanceId => Str, LayerIds => ArrayRef[Str])

Each argument is described in detail in: L<Paws::OpsWorks::AssignInstance>

Returns: nothing

  

Assign a registered instance to a layer.

=over

=item * You can assign registered on-premises instances to any layer
type.

=item * You can assign registered Amazon EC2 instances only to custom
layers.

=item * You cannot use this action with instances that were created
with AWS OpsWorks.

=back

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 AssignVolume(VolumeId => Str, [InstanceId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::AssignVolume>

Returns: nothing

  

Assigns one of the stack's registered Amazon EBS volumes to a specified
instance. The volume must first be registered with the stack by calling
RegisterVolume. After you register the volume, you must call
UpdateVolume to specify a mount point before calling C<AssignVolume>.
For more information, see Resource Management.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 AssociateElasticIp(ElasticIp => Str, [InstanceId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::AssociateElasticIp>

Returns: nothing

  

Associates one of the stack's registered Elastic IP addresses with a
specified instance. The address must first be registered with the stack
by calling RegisterElasticIp. For more information, see Resource
Management.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 AttachElasticLoadBalancer(ElasticLoadBalancerName => Str, LayerId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::AttachElasticLoadBalancer>

Returns: nothing

  

Attaches an Elastic Load Balancing load balancer to a specified layer.
For more information, see Elastic Load Balancing.

You must create the Elastic Load Balancing instance separately, by
using the Elastic Load Balancing console, API, or CLI. For more
information, see Elastic Load Balancing Developer Guide.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 CloneStack(ServiceRoleArn => Str, SourceStackId => Str, [AgentVersion => Str, Attributes => Paws::OpsWorks::StackAttributes, ChefConfiguration => Paws::OpsWorks::ChefConfiguration, CloneAppIds => ArrayRef[Str], ClonePermissions => Bool, ConfigurationManager => Paws::OpsWorks::StackConfigurationManager, CustomCookbooksSource => Paws::OpsWorks::Source, CustomJson => Str, DefaultAvailabilityZone => Str, DefaultInstanceProfileArn => Str, DefaultOs => Str, DefaultRootDeviceType => Str, DefaultSshKeyName => Str, DefaultSubnetId => Str, HostnameTheme => Str, Name => Str, Region => Str, UseCustomCookbooks => Bool, UseOpsworksSecurityGroups => Bool, VpcId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::CloneStack>

Returns: a L<Paws::OpsWorks::CloneStackResult> instance

  

Creates a clone of a specified stack. For more information, see Clone a
Stack. By default, all parameters are set to the values used by the
parent stack.

B<Required Permissions>: To use this action, an IAM user must have an
attached policy that explicitly grants permissions. For more
information on user permissions, see Managing User Permissions.











=head2 CreateApp(Name => Str, StackId => Str, Type => Str, [AppSource => Paws::OpsWorks::Source, Attributes => Paws::OpsWorks::AppAttributes, DataSources => ArrayRef[Paws::OpsWorks::DataSource], Description => Str, Domains => ArrayRef[Str], EnableSsl => Bool, Environment => ArrayRef[Paws::OpsWorks::EnvironmentVariable], Shortname => Str, SslConfiguration => Paws::OpsWorks::SslConfiguration])

Each argument is described in detail in: L<Paws::OpsWorks::CreateApp>

Returns: a L<Paws::OpsWorks::CreateAppResult> instance

  

Creates an app for a specified stack. For more information, see
Creating Apps.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 CreateDeployment(Command => Paws::OpsWorks::DeploymentCommand, StackId => Str, [AppId => Str, Comment => Str, CustomJson => Str, InstanceIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::OpsWorks::CreateDeployment>

Returns: a L<Paws::OpsWorks::CreateDeploymentResult> instance

  

Runs deployment or stack commands. For more information, see Deploying
Apps and Run Stack Commands.

B<Required Permissions>: To use this action, an IAM user must have a
Deploy or Manage permissions level for the stack, or an attached policy
that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 CreateInstance(InstanceType => Str, LayerIds => ArrayRef[Str], StackId => Str, [AgentVersion => Str, AmiId => Str, Architecture => Str, AutoScalingType => Str, AvailabilityZone => Str, BlockDeviceMappings => ArrayRef[Paws::OpsWorks::BlockDeviceMapping], EbsOptimized => Bool, Hostname => Str, InstallUpdatesOnBoot => Bool, Os => Str, RootDeviceType => Str, SshKeyName => Str, SubnetId => Str, VirtualizationType => Str])

Each argument is described in detail in: L<Paws::OpsWorks::CreateInstance>

Returns: a L<Paws::OpsWorks::CreateInstanceResult> instance

  

Creates an instance in a specified stack. For more information, see
Adding an Instance to a Layer.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 CreateLayer(Name => Str, Shortname => Str, StackId => Str, Type => Str, [Attributes => Paws::OpsWorks::LayerAttributes, AutoAssignElasticIps => Bool, AutoAssignPublicIps => Bool, CustomInstanceProfileArn => Str, CustomRecipes => Paws::OpsWorks::Recipes, CustomSecurityGroupIds => ArrayRef[Str], EnableAutoHealing => Bool, InstallUpdatesOnBoot => Bool, LifecycleEventConfiguration => Paws::OpsWorks::LifecycleEventConfiguration, Packages => ArrayRef[Str], UseEbsOptimizedInstances => Bool, VolumeConfigurations => ArrayRef[Paws::OpsWorks::VolumeConfiguration]])

Each argument is described in detail in: L<Paws::OpsWorks::CreateLayer>

Returns: a L<Paws::OpsWorks::CreateLayerResult> instance

  

Creates a layer. For more information, see How to Create a Layer.

You should use B<CreateLayer> for noncustom layer types such as PHP App
Server only if the stack does not have an existing layer of that type.
A stack can have at most one instance of each noncustom layer; if you
attempt to create a second instance, B<CreateLayer> fails. A stack can
have an arbitrary number of custom layers, so you can call
B<CreateLayer> as many times as you like for that layer type.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 CreateStack(DefaultInstanceProfileArn => Str, Name => Str, Region => Str, ServiceRoleArn => Str, [AgentVersion => Str, Attributes => Paws::OpsWorks::StackAttributes, ChefConfiguration => Paws::OpsWorks::ChefConfiguration, ConfigurationManager => Paws::OpsWorks::StackConfigurationManager, CustomCookbooksSource => Paws::OpsWorks::Source, CustomJson => Str, DefaultAvailabilityZone => Str, DefaultOs => Str, DefaultRootDeviceType => Str, DefaultSshKeyName => Str, DefaultSubnetId => Str, HostnameTheme => Str, UseCustomCookbooks => Bool, UseOpsworksSecurityGroups => Bool, VpcId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::CreateStack>

Returns: a L<Paws::OpsWorks::CreateStackResult> instance

  

Creates a new stack. For more information, see Create a New Stack.

B<Required Permissions>: To use this action, an IAM user must have an
attached policy that explicitly grants permissions. For more
information on user permissions, see Managing User Permissions.











=head2 CreateUserProfile(IamUserArn => Str, [AllowSelfManagement => Bool, SshPublicKey => Str, SshUsername => Str])

Each argument is described in detail in: L<Paws::OpsWorks::CreateUserProfile>

Returns: a L<Paws::OpsWorks::CreateUserProfileResult> instance

  

Creates a new user profile.

B<Required Permissions>: To use this action, an IAM user must have an
attached policy that explicitly grants permissions. For more
information on user permissions, see Managing User Permissions.











=head2 DeleteApp(AppId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::DeleteApp>

Returns: nothing

  

Deletes a specified app.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DeleteInstance(InstanceId => Str, [DeleteElasticIp => Bool, DeleteVolumes => Bool])

Each argument is described in detail in: L<Paws::OpsWorks::DeleteInstance>

Returns: nothing

  

Deletes a specified instance, which terminates the associated Amazon
EC2 instance. You must stop an instance before you can delete it.

For more information, see Deleting Instances.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DeleteLayer(LayerId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::DeleteLayer>

Returns: nothing

  

Deletes a specified layer. You must first stop and then delete all
associated instances or unassign registered instances. For more
information, see How to Delete a Layer.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DeleteStack(StackId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::DeleteStack>

Returns: nothing

  

Deletes a specified stack. You must first delete all instances, layers,
and apps or deregister registered instances. For more information, see
Shut Down a Stack.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DeleteUserProfile(IamUserArn => Str)

Each argument is described in detail in: L<Paws::OpsWorks::DeleteUserProfile>

Returns: nothing

  

Deletes a user profile.

B<Required Permissions>: To use this action, an IAM user must have an
attached policy that explicitly grants permissions. For more
information on user permissions, see Managing User Permissions.











=head2 DeregisterElasticIp(ElasticIp => Str)

Each argument is described in detail in: L<Paws::OpsWorks::DeregisterElasticIp>

Returns: nothing

  

Deregisters a specified Elastic IP address. The address can then be
registered by another stack. For more information, see Resource
Management.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DeregisterInstance(InstanceId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::DeregisterInstance>

Returns: nothing

  

Deregister a registered Amazon EC2 or on-premises instance. This action
removes the instance from the stack and returns it to your control.
This action can not be used with instances that were created with AWS
OpsWorks.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DeregisterRdsDbInstance(RdsDbInstanceArn => Str)

Each argument is described in detail in: L<Paws::OpsWorks::DeregisterRdsDbInstance>

Returns: nothing

  

Deregisters an Amazon RDS instance.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DeregisterVolume(VolumeId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::DeregisterVolume>

Returns: nothing

  

Deregisters an Amazon EBS volume. The volume can then be registered by
another stack. For more information, see Resource Management.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeAgentVersions([ConfigurationManager => Paws::OpsWorks::StackConfigurationManager, StackId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeAgentVersions>

Returns: a L<Paws::OpsWorks::DescribeAgentVersionsResult> instance

  

Describes the available AWS OpsWorks agent versions. You must specify a
stack ID or a configuration manager. C<DescribeAgentVersions> returns a
list of available agent versions for the specified stack or
configuration manager.











=head2 DescribeApps([AppIds => ArrayRef[Str], StackId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeApps>

Returns: a L<Paws::OpsWorks::DescribeAppsResult> instance

  

Requests a description of a specified set of apps.

You must specify at least one of the parameters.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeCommands([CommandIds => ArrayRef[Str], DeploymentId => Str, InstanceId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeCommands>

Returns: a L<Paws::OpsWorks::DescribeCommandsResult> instance

  

Describes the results of specified commands.

You must specify at least one of the parameters.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeDeployments([AppId => Str, DeploymentIds => ArrayRef[Str], StackId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeDeployments>

Returns: a L<Paws::OpsWorks::DescribeDeploymentsResult> instance

  

Requests a description of a specified set of deployments.

You must specify at least one of the parameters.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeElasticIps([InstanceId => Str, Ips => ArrayRef[Str], StackId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeElasticIps>

Returns: a L<Paws::OpsWorks::DescribeElasticIpsResult> instance

  

Describes Elastic IP addresses.

You must specify at least one of the parameters.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeElasticLoadBalancers([LayerIds => ArrayRef[Str], StackId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeElasticLoadBalancers>

Returns: a L<Paws::OpsWorks::DescribeElasticLoadBalancersResult> instance

  

Describes a stack's Elastic Load Balancing instances.

You must specify at least one of the parameters.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeInstances([InstanceIds => ArrayRef[Str], LayerId => Str, StackId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeInstances>

Returns: a L<Paws::OpsWorks::DescribeInstancesResult> instance

  

Requests a description of a set of instances.

You must specify at least one of the parameters.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeLayers([LayerIds => ArrayRef[Str], StackId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeLayers>

Returns: a L<Paws::OpsWorks::DescribeLayersResult> instance

  

Requests a description of one or more layers in a specified stack.

You must specify at least one of the parameters.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeLoadBasedAutoScaling(LayerIds => ArrayRef[Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeLoadBasedAutoScaling>

Returns: a L<Paws::OpsWorks::DescribeLoadBasedAutoScalingResult> instance

  

Describes load-based auto scaling configurations for specified layers.

You must specify at least one of the parameters.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeMyUserProfile( => )

Each argument is described in detail in: L<Paws::OpsWorks::DescribeMyUserProfile>

Returns: a L<Paws::OpsWorks::DescribeMyUserProfileResult> instance

  

Describes a user's SSH information.

B<Required Permissions>: To use this action, an IAM user must have
self-management enabled or an attached policy that explicitly grants
permissions. For more information on user permissions, see Managing
User Permissions.











=head2 DescribePermissions([IamUserArn => Str, StackId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribePermissions>

Returns: a L<Paws::OpsWorks::DescribePermissionsResult> instance

  

Describes the permissions for a specified stack.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeRaidArrays([InstanceId => Str, RaidArrayIds => ArrayRef[Str], StackId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeRaidArrays>

Returns: a L<Paws::OpsWorks::DescribeRaidArraysResult> instance

  

Describe an instance's RAID arrays.

You must specify at least one of the parameters.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeRdsDbInstances(StackId => Str, [RdsDbInstanceArns => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeRdsDbInstances>

Returns: a L<Paws::OpsWorks::DescribeRdsDbInstancesResult> instance

  

Describes Amazon RDS instances.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeServiceErrors([InstanceId => Str, ServiceErrorIds => ArrayRef[Str], StackId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeServiceErrors>

Returns: a L<Paws::OpsWorks::DescribeServiceErrorsResult> instance

  

Describes AWS OpsWorks service errors.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeStackProvisioningParameters(StackId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::DescribeStackProvisioningParameters>

Returns: a L<Paws::OpsWorks::DescribeStackProvisioningParametersResult> instance

  

Requests a description of a stack's provisioning parameters.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeStacks([StackIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeStacks>

Returns: a L<Paws::OpsWorks::DescribeStacksResult> instance

  

Requests a description of one or more stacks.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeStackSummary(StackId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::DescribeStackSummary>

Returns: a L<Paws::OpsWorks::DescribeStackSummaryResult> instance

  

Describes the number of layers and apps in a specified stack, and the
number of instances in each state, such as C<running_setup> or
C<online>.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeTimeBasedAutoScaling(InstanceIds => ArrayRef[Str])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeTimeBasedAutoScaling>

Returns: a L<Paws::OpsWorks::DescribeTimeBasedAutoScalingResult> instance

  

Describes time-based auto scaling configurations for specified
instances.

You must specify at least one of the parameters.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DescribeUserProfiles([IamUserArns => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeUserProfiles>

Returns: a L<Paws::OpsWorks::DescribeUserProfilesResult> instance

  

Describe specified users.

B<Required Permissions>: To use this action, an IAM user must have an
attached policy that explicitly grants permissions. For more
information on user permissions, see Managing User Permissions.











=head2 DescribeVolumes([InstanceId => Str, RaidArrayId => Str, StackId => Str, VolumeIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::OpsWorks::DescribeVolumes>

Returns: a L<Paws::OpsWorks::DescribeVolumesResult> instance

  

Describes an instance's Amazon EBS volumes.

You must specify at least one of the parameters.

B<Required Permissions>: To use this action, an IAM user must have a
Show, Deploy, or Manage permissions level for the stack, or an attached
policy that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DetachElasticLoadBalancer(ElasticLoadBalancerName => Str, LayerId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::DetachElasticLoadBalancer>

Returns: nothing

  

Detaches a specified Elastic Load Balancing instance from its layer.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 DisassociateElasticIp(ElasticIp => Str)

Each argument is described in detail in: L<Paws::OpsWorks::DisassociateElasticIp>

Returns: nothing

  

Disassociates an Elastic IP address from its instance. The address
remains registered with the stack. For more information, see Resource
Management.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 GetHostnameSuggestion(LayerId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::GetHostnameSuggestion>

Returns: a L<Paws::OpsWorks::GetHostnameSuggestionResult> instance

  

Gets a generated host name for the specified layer, based on the
current host name theme.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 GrantAccess(InstanceId => Str, [ValidForInMinutes => Int])

Each argument is described in detail in: L<Paws::OpsWorks::GrantAccess>

Returns: a L<Paws::OpsWorks::GrantAccessResult> instance

  

This action can be used only with Windows stacks.

Grants RDP access to a Windows instance for a specified time period.











=head2 RebootInstance(InstanceId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::RebootInstance>

Returns: nothing

  

Reboots a specified instance. For more information, see Starting,
Stopping, and Rebooting Instances.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 RegisterElasticIp(ElasticIp => Str, StackId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::RegisterElasticIp>

Returns: a L<Paws::OpsWorks::RegisterElasticIpResult> instance

  

Registers an Elastic IP address with a specified stack. An address can
be registered with only one stack at a time. If the address is already
registered, you must first deregister it by calling
DeregisterElasticIp. For more information, see Resource Management.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 RegisterInstance(StackId => Str, [Hostname => Str, InstanceIdentity => Paws::OpsWorks::InstanceIdentity, PrivateIp => Str, PublicIp => Str, RsaPublicKey => Str, RsaPublicKeyFingerprint => Str])

Each argument is described in detail in: L<Paws::OpsWorks::RegisterInstance>

Returns: a L<Paws::OpsWorks::RegisterInstanceResult> instance

  

Registers instances with a specified stack that were created outside of
AWS OpsWorks.

We do not recommend using this action to register instances. The
complete registration operation has two primary steps, installing the
AWS OpsWorks agent on the instance and registering the instance with
the stack. C<RegisterInstance> handles only the second step. You should
instead use the AWS CLI C<register> command, which performs the entire
registration operation. For more information, see Registering an
Instance with an AWS OpsWorks Stack.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 RegisterRdsDbInstance(DbPassword => Str, DbUser => Str, RdsDbInstanceArn => Str, StackId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::RegisterRdsDbInstance>

Returns: nothing

  

Registers an Amazon RDS instance with a stack.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 RegisterVolume(StackId => Str, [Ec2VolumeId => Str])

Each argument is described in detail in: L<Paws::OpsWorks::RegisterVolume>

Returns: a L<Paws::OpsWorks::RegisterVolumeResult> instance

  

Registers an Amazon EBS volume with a specified stack. A volume can be
registered with only one stack at a time. If the volume is already
registered, you must first deregister it by calling DeregisterVolume.
For more information, see Resource Management.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 SetLoadBasedAutoScaling(LayerId => Str, [DownScaling => Paws::OpsWorks::AutoScalingThresholds, Enable => Bool, UpScaling => Paws::OpsWorks::AutoScalingThresholds])

Each argument is described in detail in: L<Paws::OpsWorks::SetLoadBasedAutoScaling>

Returns: nothing

  

Specify the load-based auto scaling configuration for a specified
layer. For more information, see Managing Load with Time-based and
Load-based Instances.

To use load-based auto scaling, you must create a set of load-based
auto scaling instances. Load-based auto scaling operates only on the
instances from that set, so you must ensure that you have created
enough instances to handle the maximum anticipated load.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 SetPermission(IamUserArn => Str, StackId => Str, [AllowSsh => Bool, AllowSudo => Bool, Level => Str])

Each argument is described in detail in: L<Paws::OpsWorks::SetPermission>

Returns: nothing

  

Specifies a user's permissions. For more information, see Security and
Permissions.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 SetTimeBasedAutoScaling(InstanceId => Str, [AutoScalingSchedule => Paws::OpsWorks::WeeklyAutoScalingSchedule])

Each argument is described in detail in: L<Paws::OpsWorks::SetTimeBasedAutoScaling>

Returns: nothing

  

Specify the time-based auto scaling configuration for a specified
instance. For more information, see Managing Load with Time-based and
Load-based Instances.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 StartInstance(InstanceId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::StartInstance>

Returns: nothing

  

Starts a specified instance. For more information, see Starting,
Stopping, and Rebooting Instances.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 StartStack(StackId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::StartStack>

Returns: nothing

  

Starts a stack's instances.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 StopInstance(InstanceId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::StopInstance>

Returns: nothing

  

Stops a specified instance. When you stop a standard instance, the data
disappears and must be reinstalled when you restart the instance. You
can stop an Amazon EBS-backed instance without losing data. For more
information, see Starting, Stopping, and Rebooting Instances.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 StopStack(StackId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::StopStack>

Returns: nothing

  

Stops a specified stack.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 UnassignInstance(InstanceId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::UnassignInstance>

Returns: nothing

  

Unassigns a registered instance from all of it's layers. The instance
remains in the stack as an unassigned instance and can be assigned to
another layer, as needed. You cannot use this action with instances
that were created with AWS OpsWorks.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 UnassignVolume(VolumeId => Str)

Each argument is described in detail in: L<Paws::OpsWorks::UnassignVolume>

Returns: nothing

  

Unassigns an assigned Amazon EBS volume. The volume remains registered
with the stack. For more information, see Resource Management.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 UpdateApp(AppId => Str, [AppSource => Paws::OpsWorks::Source, Attributes => Paws::OpsWorks::AppAttributes, DataSources => ArrayRef[Paws::OpsWorks::DataSource], Description => Str, Domains => ArrayRef[Str], EnableSsl => Bool, Environment => ArrayRef[Paws::OpsWorks::EnvironmentVariable], Name => Str, SslConfiguration => Paws::OpsWorks::SslConfiguration, Type => Str])

Each argument is described in detail in: L<Paws::OpsWorks::UpdateApp>

Returns: nothing

  

Updates a specified app.

B<Required Permissions>: To use this action, an IAM user must have a
Deploy or Manage permissions level for the stack, or an attached policy
that explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 UpdateElasticIp(ElasticIp => Str, [Name => Str])

Each argument is described in detail in: L<Paws::OpsWorks::UpdateElasticIp>

Returns: nothing

  

Updates a registered Elastic IP address's name. For more information,
see Resource Management.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 UpdateInstance(InstanceId => Str, [AgentVersion => Str, AmiId => Str, Architecture => Str, AutoScalingType => Str, EbsOptimized => Bool, Hostname => Str, InstallUpdatesOnBoot => Bool, InstanceType => Str, LayerIds => ArrayRef[Str], Os => Str, SshKeyName => Str])

Each argument is described in detail in: L<Paws::OpsWorks::UpdateInstance>

Returns: nothing

  

Updates a specified instance.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 UpdateLayer(LayerId => Str, [Attributes => Paws::OpsWorks::LayerAttributes, AutoAssignElasticIps => Bool, AutoAssignPublicIps => Bool, CustomInstanceProfileArn => Str, CustomRecipes => Paws::OpsWorks::Recipes, CustomSecurityGroupIds => ArrayRef[Str], EnableAutoHealing => Bool, InstallUpdatesOnBoot => Bool, LifecycleEventConfiguration => Paws::OpsWorks::LifecycleEventConfiguration, Name => Str, Packages => ArrayRef[Str], Shortname => Str, UseEbsOptimizedInstances => Bool, VolumeConfigurations => ArrayRef[Paws::OpsWorks::VolumeConfiguration]])

Each argument is described in detail in: L<Paws::OpsWorks::UpdateLayer>

Returns: nothing

  

Updates a specified layer.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 UpdateMyUserProfile([SshPublicKey => Str])

Each argument is described in detail in: L<Paws::OpsWorks::UpdateMyUserProfile>

Returns: nothing

  

Updates a user's SSH public key.

B<Required Permissions>: To use this action, an IAM user must have
self-management enabled or an attached policy that explicitly grants
permissions. For more information on user permissions, see Managing
User Permissions.











=head2 UpdateRdsDbInstance(RdsDbInstanceArn => Str, [DbPassword => Str, DbUser => Str])

Each argument is described in detail in: L<Paws::OpsWorks::UpdateRdsDbInstance>

Returns: nothing

  

Updates an Amazon RDS instance.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 UpdateStack(StackId => Str, [AgentVersion => Str, Attributes => Paws::OpsWorks::StackAttributes, ChefConfiguration => Paws::OpsWorks::ChefConfiguration, ConfigurationManager => Paws::OpsWorks::StackConfigurationManager, CustomCookbooksSource => Paws::OpsWorks::Source, CustomJson => Str, DefaultAvailabilityZone => Str, DefaultInstanceProfileArn => Str, DefaultOs => Str, DefaultRootDeviceType => Str, DefaultSshKeyName => Str, DefaultSubnetId => Str, HostnameTheme => Str, Name => Str, ServiceRoleArn => Str, UseCustomCookbooks => Bool, UseOpsworksSecurityGroups => Bool])

Each argument is described in detail in: L<Paws::OpsWorks::UpdateStack>

Returns: nothing

  

Updates a specified stack.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head2 UpdateUserProfile(IamUserArn => Str, [AllowSelfManagement => Bool, SshPublicKey => Str, SshUsername => Str])

Each argument is described in detail in: L<Paws::OpsWorks::UpdateUserProfile>

Returns: nothing

  

Updates a specified user profile.

B<Required Permissions>: To use this action, an IAM user must have an
attached policy that explicitly grants permissions. For more
information on user permissions, see Managing User Permissions.











=head2 UpdateVolume(VolumeId => Str, [MountPoint => Str, Name => Str])

Each argument is described in detail in: L<Paws::OpsWorks::UpdateVolume>

Returns: nothing

  

Updates an Amazon EBS volume's name or mount point. For more
information, see Resource Management.

B<Required Permissions>: To use this action, an IAM user must have a
Manage permissions level for the stack, or an attached policy that
explicitly grants permissions. For more information on user
permissions, see Managing User Permissions.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

