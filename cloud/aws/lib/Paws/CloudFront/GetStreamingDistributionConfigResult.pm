
package Paws::CloudFront::GetStreamingDistributionConfigResult {
  use Moose;
  has ETag => (is => 'ro', isa => 'Str');
  has StreamingDistributionConfig => (is => 'ro', isa => 'Paws::CloudFront::StreamingDistributionConfig');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFront:: - Arguments for method  on Paws::CloudFront

=head1 DESCRIPTION

This class represents the parameters used for calling the method  on the 
Amazon CloudFront service. Use the attributes of this class
as arguments to method .

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to .

As an example:

  $service_obj->(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ETag => Str

  

The current version of the configuration. For example: E2QWRUHAPOMQZL.










=head2 StreamingDistributionConfig => Paws::CloudFront::StreamingDistributionConfig

  

The streaming distribution's configuration information.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method  in L<Paws::CloudFront>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

