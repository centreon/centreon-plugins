
package Paws::Support::CreateCase {
  use Moose;
  has attachmentSetId => (is => 'ro', isa => 'Str');
  has categoryCode => (is => 'ro', isa => 'Str');
  has ccEmailAddresses => (is => 'ro', isa => 'ArrayRef[Str]');
  has communicationBody => (is => 'ro', isa => 'Str', required => 1);
  has issueType => (is => 'ro', isa => 'Str');
  has language => (is => 'ro', isa => 'Str');
  has serviceCode => (is => 'ro', isa => 'Str');
  has severityCode => (is => 'ro', isa => 'Str');
  has subject => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateCase');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Support::CreateCaseResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Support::CreateCase - Arguments for method CreateCase on Paws::Support

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateCase on the 
AWS Support service. Use the attributes of this class
as arguments to method CreateCase.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateCase.

As an example:

  $service_obj->CreateCase(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 attachmentSetId => Str

  

The ID of a set of one or more attachments for the case. Create the set
by using AddAttachmentsToSet.










=head2 categoryCode => Str

  

The category of problem for the AWS Support case.










=head2 ccEmailAddresses => ArrayRef[Str]

  

A list of email addresses that AWS Support copies on case
correspondence.










=head2 B<REQUIRED> communicationBody => Str

  

The communication body text when you create an AWS Support case by
calling CreateCase.










=head2 issueType => Str

  

The type of issue for the case. You can specify either
"customer-service" or "technical." If you do not indicate a value, the
default is "technical."










=head2 language => Str

  

The ISO 639-1 code for the language in which AWS provides support. AWS
Support currently supports English ("en") and Japanese ("ja"). Language
parameters must be passed explicitly for operations that take them.










=head2 serviceCode => Str

  

The code for the AWS service returned by the call to DescribeServices.










=head2 severityCode => Str

  

The code for the severity level returned by the call to
DescribeSeverityLevels.

The availability of severity levels depends on each customer's support
subscription. In other words, your subscription may not necessarily
require the urgent level of response time.










=head2 B<REQUIRED> subject => Str

  

The title of the AWS Support case.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateCase in L<Paws::Support>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

