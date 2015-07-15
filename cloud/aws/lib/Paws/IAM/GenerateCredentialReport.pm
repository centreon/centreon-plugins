
package Paws::IAM::GenerateCredentialReport {
  use Moose;

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GenerateCredentialReport');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::IAM::GenerateCredentialReportResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'GenerateCredentialReportResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GenerateCredentialReport - Arguments for method GenerateCredentialReport on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method GenerateCredentialReport on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method GenerateCredentialReport.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GenerateCredentialReport.

As an example:

  $service_obj->GenerateCredentialReport(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GenerateCredentialReport in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

