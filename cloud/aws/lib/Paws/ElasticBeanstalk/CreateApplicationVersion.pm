
package Paws::ElasticBeanstalk::CreateApplicationVersion {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str', required => 1);
  has AutoCreateApplication => (is => 'ro', isa => 'Bool');
  has Description => (is => 'ro', isa => 'Str');
  has SourceBundle => (is => 'ro', isa => 'Paws::ElasticBeanstalk::S3Location');
  has VersionLabel => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateApplicationVersion');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::ApplicationVersionDescriptionMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateApplicationVersionResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::CreateApplicationVersion - Arguments for method CreateApplicationVersion on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateApplicationVersion on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method CreateApplicationVersion.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateApplicationVersion.

As an example:

  $service_obj->CreateApplicationVersion(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ApplicationName => Str

  

The name of the application. If no application is found with this name,
and C<AutoCreateApplication> is C<false>, returns an
C<InvalidParameterValue> error.










=head2 AutoCreateApplication => Bool

  

Determines how the system behaves if the specified application for this
version does not already exist:

C<true>: Automatically creates the specified application for this
version if it does not already exist.

C<false>: Returns an C<InvalidParameterValue> if the specified
application for this version does not already exist.

=over

=item * C<true> : Automatically creates the specified application for
this release if it does not already exist.

=item * C<false> : Throws an C<InvalidParameterValue> if the specified
application for this release does not already exist.

=back

Default: C<false>

Valid Values: C<true> | C<false>










=head2 Description => Str

  

Describes this version.










=head2 SourceBundle => Paws::ElasticBeanstalk::S3Location

  

The Amazon S3 bucket and key that identify the location of the source
bundle for this version.

If data found at the Amazon S3 location exceeds the maximum allowed
source bundle size, AWS Elastic Beanstalk returns an
C<InvalidParameterValue> error. The maximum size allowed is 512 MB.

Default: If not specified, AWS Elastic Beanstalk uses a sample
application. If only partially specified (for example, a bucket is
provided but not the key) or if no data is found at the Amazon S3
location, AWS Elastic Beanstalk returns an
C<InvalidParameterCombination> error.










=head2 B<REQUIRED> VersionLabel => Str

  

A label identifying this version.

Constraint: Must be unique per application. If an application version
already exists with this label for the specified application, AWS
Elastic Beanstalk returns an C<InvalidParameterValue> error.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateApplicationVersion in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

