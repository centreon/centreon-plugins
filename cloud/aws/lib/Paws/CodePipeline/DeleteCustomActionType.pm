
package Paws::CodePipeline::DeleteCustomActionType {
  use Moose;
  has category => (is => 'ro', isa => 'Str', required => 1);
  has provider => (is => 'ro', isa => 'Str', required => 1);
  has version => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteCustomActionType');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::DeleteCustomActionType - Arguments for method DeleteCustomActionType on Paws::CodePipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteCustomActionType on the 
AWS CodePipeline service. Use the attributes of this class
as arguments to method DeleteCustomActionType.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteCustomActionType.

As an example:

  $service_obj->DeleteCustomActionType(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> category => Str

  

The category of the custom action that you want to delete, such as
source or deploy.










=head2 B<REQUIRED> provider => Str

  

The provider of the service used in the custom action, such as AWS
CodeDeploy.










=head2 B<REQUIRED> version => Str

  

The version of the custom action to delete.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteCustomActionType in L<Paws::CodePipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

