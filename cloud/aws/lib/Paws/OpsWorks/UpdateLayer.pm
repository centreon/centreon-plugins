
package Paws::OpsWorks::UpdateLayer {
  use Moose;
  has Attributes => (is => 'ro', isa => 'Paws::OpsWorks::LayerAttributes');
  has AutoAssignElasticIps => (is => 'ro', isa => 'Bool');
  has AutoAssignPublicIps => (is => 'ro', isa => 'Bool');
  has CustomInstanceProfileArn => (is => 'ro', isa => 'Str');
  has CustomRecipes => (is => 'ro', isa => 'Paws::OpsWorks::Recipes');
  has CustomSecurityGroupIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has EnableAutoHealing => (is => 'ro', isa => 'Bool');
  has InstallUpdatesOnBoot => (is => 'ro', isa => 'Bool');
  has LayerId => (is => 'ro', isa => 'Str', required => 1);
  has LifecycleEventConfiguration => (is => 'ro', isa => 'Paws::OpsWorks::LifecycleEventConfiguration');
  has Name => (is => 'ro', isa => 'Str');
  has Packages => (is => 'ro', isa => 'ArrayRef[Str]');
  has Shortname => (is => 'ro', isa => 'Str');
  has UseEbsOptimizedInstances => (is => 'ro', isa => 'Bool');
  has VolumeConfigurations => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::VolumeConfiguration]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateLayer');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::UpdateLayer - Arguments for method UpdateLayer on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateLayer on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method UpdateLayer.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateLayer.

As an example:

  $service_obj->UpdateLayer(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Attributes => Paws::OpsWorks::LayerAttributes

  

One or more user-defined key/value pairs to be added to the stack
attributes.










=head2 AutoAssignElasticIps => Bool

  

Whether to automatically assign an Elastic IP address to the layer's
instances. For more information, see How to Edit a Layer.










=head2 AutoAssignPublicIps => Bool

  

For stacks that are running in a VPC, whether to automatically assign a
public IP address to the layer's instances. For more information, see
How to Edit a Layer.










=head2 CustomInstanceProfileArn => Str

  

The ARN of an IAM profile to be used for all of the layer's EC2
instances. For more information about IAM ARNs, see Using Identifiers.










=head2 CustomRecipes => Paws::OpsWorks::Recipes

  

A C<LayerCustomRecipes> object that specifies the layer's custom
recipes.










=head2 CustomSecurityGroupIds => ArrayRef[Str]

  

An array containing the layer's custom security group IDs.










=head2 EnableAutoHealing => Bool

  

Whether to disable auto healing for the layer.










=head2 InstallUpdatesOnBoot => Bool

  

Whether to install operating system and package updates when the
instance boots. The default value is C<true>. To control when updates
are installed, set this value to C<false>. You must then update your
instances manually by using CreateDeployment to run the
C<update_dependencies> stack command or manually running C<yum> (Amazon
Linux) or C<apt-get> (Ubuntu) on the instances.

We strongly recommend using the default value of C<true>, to ensure
that your instances have the latest security updates.










=head2 B<REQUIRED> LayerId => Str

  

The layer ID.










=head2 LifecycleEventConfiguration => Paws::OpsWorks::LifecycleEventConfiguration

  










=head2 Name => Str

  

The layer name, which is used by the console.










=head2 Packages => ArrayRef[Str]

  

An array of C<Package> objects that describe the layer's packages.










=head2 Shortname => Str

  

For custom layers only, use this parameter to specify the layer's short
name, which is used internally by AWS OpsWorksand by Chef. The short
name is also used as the name for the directory where your app files
are installed. It can have a maximum of 200 characters and must be in
the following format: /\A[a-z0-9\-\_\.]+\Z/.

The built-in layers' short names are defined by AWS OpsWorks. For more
information, see the Layer Reference










=head2 UseEbsOptimizedInstances => Bool

  

Whether to use Amazon EBS-optimized instances.










=head2 VolumeConfigurations => ArrayRef[Paws::OpsWorks::VolumeConfiguration]

  

A C<VolumeConfigurations> object that describes the layer's Amazon EBS
volumes.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateLayer in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

