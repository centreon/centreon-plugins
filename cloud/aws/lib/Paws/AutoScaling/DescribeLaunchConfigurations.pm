
package Paws::AutoScaling::DescribeLaunchConfigurations {
  use Moose;
  has LaunchConfigurationNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeLaunchConfigurations');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::AutoScaling::LaunchConfigurationsType');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeLaunchConfigurationsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribeLaunchConfigurations - Arguments for method DescribeLaunchConfigurations on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeLaunchConfigurations on the 
Auto Scaling service. Use the attributes of this class
as arguments to method DescribeLaunchConfigurations.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeLaunchConfigurations.

As an example:

  $service_obj->DescribeLaunchConfigurations(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 LaunchConfigurationNames => ArrayRef[Str]

  

The launch configuration names.










=head2 MaxRecords => Int

  

The maximum number of items to return with this call. The default is
100.










=head2 NextToken => Str

  

The token for the next set of items to return. (You received this token
from a previous call.)












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeLaunchConfigurations in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

