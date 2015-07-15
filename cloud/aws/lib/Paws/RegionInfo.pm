
package Paws::RegionInfo {

  sub get {
    my $data;
    $data = {
    _default => [
      {
        constraints => [
          [
            'region',
            'startsWith',
            'cn-'
          ]
        ],
        properties => {
          signatureVersion => 'v4'
        },
        uri => '{scheme}://{service}.{region}.amazonaws.com.cn'
      },
      {
        constraints => [
          [
            'region',
            'notEquals',
            undef
          ]
        ],
        uri => '{scheme}://{service}.{region}.amazonaws.com'
      }
    ],
    cloudfront => [
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
    ],
    dynamodb => [
      {
        constraints => [
          [
            'region',
            'equals',
            'local'
          ]
        ],
        properties => {
          credentialScope => {
            region => 'us-east-1',
            service => 'dynamodb'
          }
        },
        uri => 'http://localhost:8000'
      }
    ],
    elasticmapreduce => [
      {
        constraints => [
          [
            'region',
            'startsWith',
            'cn-'
          ]
        ],
        uri => 'https://elasticmapreduce.cn-north-1.amazonaws.com.cn'
      },
      {
        constraints => [
          [
            'region',
            'equals',
            'eu-central-1'
          ]
        ],
        uri => 'https://elasticmapreduce.eu-central-1.amazonaws.com'
      },
      {
        constraints => [
          [
            'region',
            'equals',
            'us-east-1'
          ]
        ],
        uri => 'https://elasticmapreduce.us-east-1.amazonaws.com'
      },
      {
        constraints => [
          [
            'region',
            'notEquals',
            undef
          ]
        ],
        uri => 'https://{region}.elasticmapreduce.amazonaws.com'
      }
    ],
    iam => [
      {
        constraints => [
          [
            'region',
            'startsWith',
            'cn-'
          ]
        ],
        uri => 'https://{service}.cn-north-1.amazonaws.com.cn'
      },
      {
        constraints => [
          [
            'region',
            'startsWith',
            'us-gov'
          ]
        ],
        uri => 'https://{service}.us-gov.amazonaws.com'
      },
      {
        properties => {
          credentialScope => {
            region => 'us-east-1'
          }
        },
        uri => 'https://iam.amazonaws.com'
      }
    ],
    importexport => [
      {
        constraints => [
          [
            'region',
            'notStartsWith',
            'cn-'
          ]
        ],
        uri => 'https://importexport.amazonaws.com'
      }
    ],
    rds => [
      {
        constraints => [
          [
            'region',
            'equals',
            'us-east-1'
          ]
        ],
        uri => 'https://rds.amazonaws.com'
      }
    ],
    route53 => [
      {
        constraints => [
          [
            'region',
            'notStartsWith',
            'cn-'
          ]
        ],
        uri => 'https://route53.amazonaws.com'
      }
    ],
    s3 => [
      {
        constraints => [
          [
            'region',
            'oneOf',
            [
              'us-east-1',
              undef
            ]
          ]
        ],
        properties => {
          credentialScope => {
            region => 'us-east-1'
          }
        },
        uri => '{scheme}://s3.amazonaws.com'
      },
      {
        constraints => [
          [
            'region',
            'startsWith',
            'cn-'
          ]
        ],
        properties => {
          signatureVersion => 's3v4'
        },
        uri => '{scheme}://{service}.{region}.amazonaws.com.cn'
      },
      {
        constraints => [
          [
            'region',
            'oneOf',
            [
              'us-east-1',
              'ap-northeast-1',
              'sa-east-1',
              'ap-southeast-1',
              'ap-southeast-2',
              'us-west-2',
              'us-west-1',
              'eu-west-1',
              'us-gov-west-1',
              'fips-us-gov-west-1'
            ]
          ]
        ],
        uri => '{scheme}://{service}-{region}.amazonaws.com'
      },
      {
        constraints => [
          [
            'region',
            'notEquals',
            undef
          ]
        ],
        properties => {
          signatureVersion => 's3v4'
        },
        uri => '{scheme}://{service}.{region}.amazonaws.com'
      }
    ],
    sdb => [
      {
        constraints => [
          [
            'region',
            'equals',
            'us-east-1'
          ]
        ],
        uri => 'https://sdb.amazonaws.com'
      }
    ],
    sqs => [
      {
        constraints => [
          [
            'region',
            'equals',
            'us-east-1'
          ]
        ],
        uri => 'https://queue.amazonaws.com'
      },
      {
        constraints => [
          [
            'region',
            'startsWith',
            'cn-'
          ]
        ],
        uri => 'https://{region}.queue.amazonaws.com.cn'
      },
      {
        constraints => [
          [
            'region',
            'notEquals',
            undef
          ]
        ],
        uri => 'https://{region}.queue.amazonaws.com'
      }
    ],
    sts => [
      {
        constraints => [
          [
            'region',
            'startsWith',
            'cn-'
          ]
        ],
        uri => '{scheme}://{service}.cn-north-1.amazonaws.com.cn'
      },
      {
        constraints => [
          [
            'region',
            'startsWith',
            'us-gov'
          ]
        ],
        uri => 'https://{service}.{region}.amazonaws.com'
      },
      {
        properties => {
          credentialScope => {
            region => 'us-east-1'
          }
        },
        uri => 'https://sts.amazonaws.com'
      }
    ]
  };

    return $data;
  }

}
1;
