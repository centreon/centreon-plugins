
package Paws::DeviceFarm::CreateUpload {
  use Moose;
  has contentType => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str', required => 1);
  has projectArn => (is => 'ro', isa => 'Str', required => 1);
  has type => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateUpload');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DeviceFarm::CreateUploadResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::CreateUpload - Arguments for method CreateUpload on Paws::DeviceFarm

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateUpload on the 
AWS Device Farm service. Use the attributes of this class
as arguments to method CreateUpload.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateUpload.

As an example:

  $service_obj->CreateUpload(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 contentType => Str

  

The upload's content type (for example, "application/octet-stream").










=head2 B<REQUIRED> name => Str

  

The upload's file name.










=head2 B<REQUIRED> projectArn => Str

  

The ARN of the project for the upload.










=head2 B<REQUIRED> type => Str

  

The upload's upload type.

Must be one of the following values:

=over

=item *

ANDROID_APP: An Android upload.

=item *

APPIUM_JAVA_JUNIT_TEST_PACKAGE: An Appium Java JUnit test package
upload.

=item *

APPIUM_JAVA_TESTNG_TEST_PACKAGE: An Appium Java TestNG test package
upload.

=item *

CALABASH_TEST_PACKAGE: A Calabash test package upload.

=item *

EXTERNAL_DATA: An external data upload.

=item *

INSTRUMENTATION_TEST_PACKAGE: An instrumentation upload.

=item *

UIAUTOMATOR_TEST_PACKAGE: A uiautomator test package upload.

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateUpload in L<Paws::DeviceFarm>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

