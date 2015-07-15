
package Paws::Config::DescribeConfigurationRecorders {
  use Moose;
  has ConfigurationRecorderNames => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeConfigurationRecorders');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Config::DescribeConfigurationRecordersResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Config::DescribeConfigurationRecorders - Arguments for method DescribeConfigurationRecorders on Paws::Config

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeConfigurationRecorders on the 
AWS Config service. Use the attributes of this class
as arguments to method DescribeConfigurationRecorders.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeConfigurationRecorders.

As an example:

  $service_obj->DescribeConfigurationRecorders(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ConfigurationRecorderNames => ArrayRef[Str]

  

A list of configuration recorder names.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeConfigurationRecorders in L<Paws::Config>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

