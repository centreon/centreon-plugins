
package Paws::ElasticBeanstalk::DeleteApplicationVersion {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str', required => 1);
  has DeleteSourceBundle => (is => 'ro', isa => 'Bool');
  has VersionLabel => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteApplicationVersion');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::DeleteApplicationVersion - Arguments for method DeleteApplicationVersion on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteApplicationVersion on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method DeleteApplicationVersion.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteApplicationVersion.

As an example:

  $service_obj->DeleteApplicationVersion(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ApplicationName => Str

  

The name of the application to delete releases from.










=head2 DeleteSourceBundle => Bool

  

Indicates whether to delete the associated source bundle from Amazon
S3:

=over

=item * C<true>: An attempt is made to delete the associated Amazon S3
source bundle specified at time of creation.

=item * C<false>: No action is taken on the Amazon S3 source bundle
specified at time of creation.

=back

Valid Values: C<true> | C<false>










=head2 B<REQUIRED> VersionLabel => Str

  

The label of the version to delete.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteApplicationVersion in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

