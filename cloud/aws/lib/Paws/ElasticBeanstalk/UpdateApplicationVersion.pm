
package Paws::ElasticBeanstalk::UpdateApplicationVersion {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str', required => 1);
  has Description => (is => 'ro', isa => 'Str');
  has VersionLabel => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateApplicationVersion');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::ApplicationVersionDescriptionMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'UpdateApplicationVersionResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::UpdateApplicationVersion - Arguments for method UpdateApplicationVersion on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateApplicationVersion on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method UpdateApplicationVersion.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateApplicationVersion.

As an example:

  $service_obj->UpdateApplicationVersion(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ApplicationName => Str

  

The name of the application associated with this version.

If no application is found with this name, C<UpdateApplication> returns
an C<InvalidParameterValue> error.










=head2 Description => Str

  

A new description for this release.










=head2 B<REQUIRED> VersionLabel => Str

  

The name of the version to update.

If no application version is found with this label,
C<UpdateApplication> returns an C<InvalidParameterValue> error.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateApplicationVersion in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

