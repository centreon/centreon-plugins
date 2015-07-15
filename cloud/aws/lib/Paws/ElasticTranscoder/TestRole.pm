
package Paws::ElasticTranscoder::TestRole {
  use Moose;
  has InputBucket => (is => 'ro', isa => 'Str', required => 1);
  has OutputBucket => (is => 'ro', isa => 'Str', required => 1);
  has Role => (is => 'ro', isa => 'Str', required => 1);
  has Topics => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'TestRole');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2012-09-25/roleTests');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticTranscoder::TestRoleResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'TestRoleResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder::TestRole - Arguments for method TestRole on Paws::ElasticTranscoder

=head1 DESCRIPTION

This class represents the parameters used for calling the method TestRole on the 
Amazon Elastic Transcoder service. Use the attributes of this class
as arguments to method TestRole.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to TestRole.

As an example:

  $service_obj->TestRole(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> InputBucket => Str

  

The Amazon S3 bucket that contains media files to be transcoded. The
action attempts to read from this bucket.










=head2 B<REQUIRED> OutputBucket => Str

  

The Amazon S3 bucket that Elastic Transcoder will write transcoded
media files to. The action attempts to read from this bucket.










=head2 B<REQUIRED> Role => Str

  

The IAM Amazon Resource Name (ARN) for the role that you want Elastic
Transcoder to test.










=head2 B<REQUIRED> Topics => ArrayRef[Str]

  

The ARNs of one or more Amazon Simple Notification Service (Amazon SNS)
topics that you want the action to send a test notification to.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method TestRole in L<Paws::ElasticTranscoder>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

