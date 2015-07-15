
package Paws::CodeDeploy::RegisterOnPremisesInstance {
  use Moose;
  has iamUserArn => (is => 'ro', isa => 'Str', required => 1);
  has instanceName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RegisterOnPremisesInstance');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::RegisterOnPremisesInstance - Arguments for method RegisterOnPremisesInstance on Paws::CodeDeploy

=head1 DESCRIPTION

This class represents the parameters used for calling the method RegisterOnPremisesInstance on the 
AWS CodeDeploy service. Use the attributes of this class
as arguments to method RegisterOnPremisesInstance.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RegisterOnPremisesInstance.

As an example:

  $service_obj->RegisterOnPremisesInstance(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> iamUserArn => Str

  

The ARN of the IAM user to associate with the on-premises instance.










=head2 B<REQUIRED> instanceName => Str

  

The name of the on-premises instance to register.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RegisterOnPremisesInstance in L<Paws::CodeDeploy>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

