
package Paws::OpsWorks::UpdateStack {
  use Moose;
  has AgentVersion => (is => 'ro', isa => 'Str');
  has Attributes => (is => 'ro', isa => 'Paws::OpsWorks::StackAttributes');
  has ChefConfiguration => (is => 'ro', isa => 'Paws::OpsWorks::ChefConfiguration');
  has ConfigurationManager => (is => 'ro', isa => 'Paws::OpsWorks::StackConfigurationManager');
  has CustomCookbooksSource => (is => 'ro', isa => 'Paws::OpsWorks::Source');
  has CustomJson => (is => 'ro', isa => 'Str');
  has DefaultAvailabilityZone => (is => 'ro', isa => 'Str');
  has DefaultInstanceProfileArn => (is => 'ro', isa => 'Str');
  has DefaultOs => (is => 'ro', isa => 'Str');
  has DefaultRootDeviceType => (is => 'ro', isa => 'Str');
  has DefaultSshKeyName => (is => 'ro', isa => 'Str');
  has DefaultSubnetId => (is => 'ro', isa => 'Str');
  has HostnameTheme => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has ServiceRoleArn => (is => 'ro', isa => 'Str');
  has StackId => (is => 'ro', isa => 'Str', required => 1);
  has UseCustomCookbooks => (is => 'ro', isa => 'Bool');
  has UseOpsworksSecurityGroups => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateStack');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::UpdateStack - Arguments for method UpdateStack on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateStack on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method UpdateStack.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateStack.

As an example:

  $service_obj->UpdateStack(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AgentVersion => Str

  

The default AWS OpsWorks agent version. You have the following options:

=over

=item * Auto-update - Set this parameter to C<LATEST>. AWS OpsWorks
automatically installs new agent versions on the stack's instances as
soon as they are available.

=item * Fixed version - Set this parameter to your preferred agent
version. To update the agent version, you must edit the stack
configuration and specify a new version. AWS OpsWorks then
automatically installs that version on the stack's instances.

=back

The default setting is C<LATEST>. To specify an agent version, you must
use the complete version number, not the abbreviated number shown on
the console. For a list of available agent version numbers, call
DescribeAgentVersions.

You can also specify an agent version when you create or update an
instance, which overrides the stack's default setting.










=head2 Attributes => Paws::OpsWorks::StackAttributes

  

One or more user-defined key-value pairs to be added to the stack
attributes.










=head2 ChefConfiguration => Paws::OpsWorks::ChefConfiguration

  

A C<ChefConfiguration> object that specifies whether to enable
Berkshelf and the Berkshelf version on Chef 11.10 stacks. For more
information, see Create a New Stack.










=head2 ConfigurationManager => Paws::OpsWorks::StackConfigurationManager

  

The configuration manager. When you clone a stack, we recommend that
you use the configuration manager to specify the Chef version: 0.9,
11.4, or 11.10. The default value is currently 11.4.










=head2 CustomCookbooksSource => Paws::OpsWorks::Source

  

=head2 CustomJson => Str

  

A string that contains user-defined, custom JSON. It can be used to
override the corresponding default stack configuration JSON values or
to pass data to recipes. The string should be in the following format
and escape characters such as '"':

C<"{\"key1\": \"value1\", \"key2\": \"value2\",...}">

For more information on custom JSON, see Use Custom JSON to Modify the
Stack Configuration Attributes.










=head2 DefaultAvailabilityZone => Str

  

The stack's default Availability Zone, which must be in the stack's
region. For more information, see Regions and Endpoints. If you also
specify a value for C<DefaultSubnetId>, the subnet must be in the same
zone. For more information, see CreateStack.










=head2 DefaultInstanceProfileArn => Str

  

The ARN of an IAM profile that is the default profile for all of the
stack's EC2 instances. For more information about IAM ARNs, see Using
Identifiers.










=head2 DefaultOs => Str

  

The stack's operating system, which must be set to one of the
following:

=over

=item * A supported Linux operating system: An Amazon Linux version,
such as C<Amazon Linux 2015.03>, C<Ubuntu 12.04 LTS>, or C<Ubuntu 14.04
LTS>.

=item * C<Microsoft Windows Server 2012 R2 Base>.

=item * A custom AMI: C<Custom>. You specify the custom AMI you want to
use when you create instances. For more information on how to use
custom AMIs with OpsWorks, see Using Custom AMIs.

=back

The default option is the stack's current operating system. For more
information on the supported operating systems, see AWS OpsWorks
Operating Systems.










=head2 DefaultRootDeviceType => Str

  

The default root device type. This value is used by default for all
instances in the stack, but you can override it when you create an
instance. For more information, see Storage for the Root Device.










=head2 DefaultSshKeyName => Str

  

A default Amazon EC2 key-pair name. The default value is C<none>. If
you specify a key-pair name, AWS OpsWorks installs the public key on
the instance and you can use the private key with an SSH client to log
in to the instance. For more information, see Using SSH to Communicate
with an Instance and Managing SSH Access. You can override this setting
by specifying a different key pair, or no key pair, when you create an
instance.










=head2 DefaultSubnetId => Str

  

The stack's default VPC subnet ID. This parameter is required if you
specify a value for the C<VpcId> parameter. All instances are launched
into this subnet unless you specify otherwise when you create the
instance. If you also specify a value for C<DefaultAvailabilityZone>,
the subnet must be in that zone. For information on default values and
when this parameter is required, see the C<VpcId> parameter
description.










=head2 HostnameTheme => Str

  

The stack's new host name theme, with spaces replaced by underscores.
The theme is used to generate host names for the stack's instances. By
default, C<HostnameTheme> is set to C<Layer_Dependent>, which creates
host names by appending integers to the layer's short name. The other
themes are:

=over

=item * C<Baked_Goods>

=item * C<Clouds>

=item * C<Europe_Cities>

=item * C<Fruits>

=item * C<Greek_Deities>

=item * C<Legendary_creatures_from_Japan>

=item * C<Planets_and_Moons>

=item * C<Roman_Deities>

=item * C<Scottish_Islands>

=item * C<US_Cities>

=item * C<Wild_Cats>

=back

To obtain a generated host name, call C<GetHostNameSuggestion>, which
returns a host name based on the current theme.










=head2 Name => Str

  

The stack's new name.










=head2 ServiceRoleArn => Str

  

The stack IAM role, which allows AWS OpsWorks to work with AWS
resources on your behalf. You must set this parameter to the ARN for an
existing IAM role. For more information about IAM ARNs, see Using
Identifiers.

There is no default value. You must set this parameter to a valid
service role ARN or the action will fail. You can specify the stack's
current service role ARN, if you prefer, but you must do so explicitly.










=head2 B<REQUIRED> StackId => Str

  

The stack ID.










=head2 UseCustomCookbooks => Bool

  

Whether the stack uses custom cookbooks.










=head2 UseOpsworksSecurityGroups => Bool

  

Whether to associate the AWS OpsWorks built-in security groups with the
stack's layers.

AWS OpsWorks provides a standard set of built-in security groups, one
for each layer, which are associated with layers by default.
C<UseOpsworksSecurityGroups> allows you to provide your own custom
security groups instead of using the built-in groups.
C<UseOpsworksSecurityGroups> has the following settings:

=over

=item * True - AWS OpsWorks automatically associates the appropriate
built-in security group with each layer (default setting). You can
associate additional security groups with a layer after you create it,
but you cannot delete the built-in security group.

=item * False - AWS OpsWorks does not associate built-in security
groups with layers. You must create appropriate EC2 security groups and
associate a security group with each layer that you create. However,
you can still manually associate a built-in security group with a layer
on. Custom security groups are required only for those layers that need
custom settings.

=back

For more information, see Create a New Stack.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateStack in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

