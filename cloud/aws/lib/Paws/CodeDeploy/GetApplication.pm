
package Paws::CodeDeploy::GetApplication {
  use Moose;
  has applicationName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetApplication');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodeDeploy::GetApplicationOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::GetApplication - Arguments for method GetApplication on Paws::CodeDeploy

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetApplication on the 
AWS CodeDeploy service. Use the attributes of this class
as arguments to method GetApplication.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetApplication.

As an example:

  $service_obj->GetApplication(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> applicationName => Str

  

The name of an existing AWS CodeDeploy application associated with the
applicable IAM user or AWS account.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetApplication in L<Paws::CodeDeploy>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

