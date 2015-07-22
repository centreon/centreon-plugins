package Paws::CloudFront {
  warn "Paws::CloudFront is not stable / supported / entirely developed";
  use Moose;
  sub service { 'cloudfront' }
  sub version { '2015-04-17' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::RestXmlCaller', 'Paws::Net::RestXMLResponse';

  has '+region_rules' => (default => sub {
    my $regioninfo;
      $regioninfo = [
    {
      constraints => [
        [
          'region',
          'notStartsWith',
          'cn-'
        ]
      ],
      properties => {
        credentialScope => {
          region => 'us-east-1'
        }
      },
      uri => 'https://cloudfront.amazonaws.com'
    }
  ];

    return $regioninfo;
  });

  
  sub CreateCloudFrontOriginAccessIdentity2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::CreateCloudFrontOriginAccessIdentity2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDistribution2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::CreateDistribution2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateInvalidation2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::CreateInvalidation2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateStreamingDistribution2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::CreateStreamingDistribution2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteCloudFrontOriginAccessIdentity2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::DeleteCloudFrontOriginAccessIdentity2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteDistribution2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::DeleteDistribution2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteStreamingDistribution2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::DeleteStreamingDistribution2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetCloudFrontOriginAccessIdentity2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::GetCloudFrontOriginAccessIdentity2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetCloudFrontOriginAccessIdentityConfig2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::GetCloudFrontOriginAccessIdentityConfig2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetDistribution2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::GetDistribution2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetDistributionConfig2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::GetDistributionConfig2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetInvalidation2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::GetInvalidation2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetStreamingDistribution2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::GetStreamingDistribution2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetStreamingDistributionConfig2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::GetStreamingDistributionConfig2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListCloudFrontOriginAccessIdentities2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::ListCloudFrontOriginAccessIdentities2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListDistributions2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::ListDistributions2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListInvalidations2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::ListInvalidations2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListStreamingDistributions2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::ListStreamingDistributions2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateCloudFrontOriginAccessIdentity2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::UpdateCloudFrontOriginAccessIdentity2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateDistribution2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::UpdateDistribution2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateStreamingDistribution2015_04_17 {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFront::UpdateStreamingDistribution2015_04_17', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFront - Perl Interface to AWS Amazon CloudFront

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('CloudFront')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



=head1 METHODS

=head2 CreateCloudFrontOriginAccessIdentity2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::CreateCloudFrontOriginAccessIdentity2015_04_17>

Returns: nothing

  


=head2 CreateDistribution2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::CreateDistribution2015_04_17>

Returns: nothing

  


=head2 CreateInvalidation2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::CreateInvalidation2015_04_17>

Returns: nothing

  


=head2 CreateStreamingDistribution2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::CreateStreamingDistribution2015_04_17>

Returns: nothing

  


=head2 DeleteCloudFrontOriginAccessIdentity2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::DeleteCloudFrontOriginAccessIdentity2015_04_17>

Returns: nothing

  


=head2 DeleteDistribution2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::DeleteDistribution2015_04_17>

Returns: nothing

  


=head2 DeleteStreamingDistribution2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::DeleteStreamingDistribution2015_04_17>

Returns: nothing

  


=head2 GetCloudFrontOriginAccessIdentity2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::GetCloudFrontOriginAccessIdentity2015_04_17>

Returns: nothing

  


=head2 GetCloudFrontOriginAccessIdentityConfig2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::GetCloudFrontOriginAccessIdentityConfig2015_04_17>

Returns: nothing

  


=head2 GetDistribution2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::GetDistribution2015_04_17>

Returns: nothing

  


=head2 GetDistributionConfig2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::GetDistributionConfig2015_04_17>

Returns: nothing

  


=head2 GetInvalidation2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::GetInvalidation2015_04_17>

Returns: nothing

  


=head2 GetStreamingDistribution2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::GetStreamingDistribution2015_04_17>

Returns: nothing

  


=head2 GetStreamingDistributionConfig2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::GetStreamingDistributionConfig2015_04_17>

Returns: nothing

  


=head2 ListCloudFrontOriginAccessIdentities2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::ListCloudFrontOriginAccessIdentities2015_04_17>

Returns: nothing

  


=head2 ListDistributions2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::ListDistributions2015_04_17>

Returns: nothing

  


=head2 ListInvalidations2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::ListInvalidations2015_04_17>

Returns: nothing

  


=head2 ListStreamingDistributions2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::ListStreamingDistributions2015_04_17>

Returns: nothing

  


=head2 UpdateCloudFrontOriginAccessIdentity2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::UpdateCloudFrontOriginAccessIdentity2015_04_17>

Returns: nothing

  


=head2 UpdateDistribution2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::UpdateDistribution2015_04_17>

Returns: nothing

  


=head2 UpdateStreamingDistribution2015_04_17( => )

Each argument is described in detail in: L<Paws::CloudFront::UpdateStreamingDistribution2015_04_17>

Returns: nothing

  


=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

