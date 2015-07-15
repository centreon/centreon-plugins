
package Paws::Support::AddCommunicationToCase {
  use Moose;
  has attachmentSetId => (is => 'ro', isa => 'Str');
  has caseId => (is => 'ro', isa => 'Str');
  has ccEmailAddresses => (is => 'ro', isa => 'ArrayRef[Str]');
  has communicationBody => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AddCommunicationToCase');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Support::AddCommunicationToCaseResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Support::AddCommunicationToCase - Arguments for method AddCommunicationToCase on Paws::Support

=head1 DESCRIPTION

This class represents the parameters used for calling the method AddCommunicationToCase on the 
AWS Support service. Use the attributes of this class
as arguments to method AddCommunicationToCase.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AddCommunicationToCase.

As an example:

  $service_obj->AddCommunicationToCase(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 attachmentSetId => Str

  

The ID of a set of one or more attachments for the communication to add
to the case. Create the set by calling AddAttachmentsToSet










=head2 caseId => Str

  

The AWS Support case ID requested or returned in the call. The case ID
is an alphanumeric string formatted as shown in this example:
case-I<12345678910-2013-c4c1d2bf33c5cf47>










=head2 ccEmailAddresses => ArrayRef[Str]

  

The email addresses in the CC line of an email to be added to the
support case.










=head2 B<REQUIRED> communicationBody => Str

  

The body of an email communication to add to the support case.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AddCommunicationToCase in L<Paws::Support>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

