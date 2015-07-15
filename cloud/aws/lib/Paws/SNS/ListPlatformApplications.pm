
package Paws::SNS::ListPlatformApplications {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListPlatformApplications');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SNS::ListPlatformApplicationsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListPlatformApplicationsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::ListPlatformApplications - Arguments for method ListPlatformApplications on Paws::SNS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListPlatformApplications on the 
Amazon Simple Notification Service service. Use the attributes of this class
as arguments to method ListPlatformApplications.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListPlatformApplications.

As an example:

  $service_obj->ListPlatformApplications(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 NextToken => Str

  

NextToken string is used when calling ListPlatformApplications action
to retrieve additional records that are available after the first page
results.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListPlatformApplications in L<Paws::SNS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

