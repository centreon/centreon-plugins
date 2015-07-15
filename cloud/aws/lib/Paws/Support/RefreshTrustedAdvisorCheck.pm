
package Paws::Support::RefreshTrustedAdvisorCheck {
  use Moose;
  has checkId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RefreshTrustedAdvisorCheck');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Support::RefreshTrustedAdvisorCheckResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Support::RefreshTrustedAdvisorCheck - Arguments for method RefreshTrustedAdvisorCheck on Paws::Support

=head1 DESCRIPTION

This class represents the parameters used for calling the method RefreshTrustedAdvisorCheck on the 
AWS Support service. Use the attributes of this class
as arguments to method RefreshTrustedAdvisorCheck.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RefreshTrustedAdvisorCheck.

As an example:

  $service_obj->RefreshTrustedAdvisorCheck(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> checkId => Str

  

The unique identifier for the Trusted Advisor check.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RefreshTrustedAdvisorCheck in L<Paws::Support>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

