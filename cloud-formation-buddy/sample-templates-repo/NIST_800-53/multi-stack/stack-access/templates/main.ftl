{
   "AWSTemplateFormatVersion": "2010-09-09",
   "Description": "Provides the base security, logging, IAM, and access configuration for the AWS account",
    "Metadata" : {
        "Stack" : {"Value" : "1"},
        "VersionDate" : { "Value" : "09292015" },
        "Identifier" : { "Value" : "stack1-access-01" },
        "Input" : { "Description" : "CloudTrail bucket name" },
        "Output" : { "Description" : "Outputs ID of all deployed resources" }
    },
   "Parameters" : {
     "pNotifyEmail" : {
 			"Description" : "Notification email for security events",
 			"Type" : "String",
  			"Default" : "distlist@example.org"
 		},
        "pS3CloudTrailBucketExisting" : {
                "Description" : "Name of EXISTING S3 log bucket for CloudTrail, bucket must already exist",
                "Type" : "String",
		"Default" : "none"
        },

        "pS3CloudTrailLocal" : {
                "Description" : "Name of new local bucket for S3 logging to create new (leave 'none' to not create local bucket), if specifying new local bucket do not use pS3CloudTrailBucketExisting",
                "Type" : "String",
		"Default" : "none"
        },
	"pCreateCloudTrail" : {
		"Description" : "Create new CloudTrail Trail (yes or no), if yes must provide Existing or Local parameter? 'no' will not setup any CloudTrail logging",
		"Type" : "String",
		"Default" : "no"
	}
   },
   "Conditions" : {
	"cCreateCloudTrail" : {
                "Fn::Not" : [
                  {
                    "Fn::Equals" : [{ "Ref" : "pCreateCloudTrail" }, "no"]
                      }
                    ]
        },
        "cExistingCloudTrailBucket" : {
                "Fn::Not" : [
                  {
                    "Fn::Equals" : [{ "Ref" : "pS3CloudTrailBucketExisting" }, "none"]
                      }
                    ]
        },
	"cCreateCloudTrailBucketLocal" : {
                "Fn::Not" : [
                  {
                    "Fn::Equals" : [{ "Ref" : "pS3CloudTrailLocal" }, "none"]
                      }
                    ]
        }
   },
   "Resources": {
      "rCloudTrailBucket": {
         "Type": "AWS::S3::Bucket",
	 "Condition" : "cCreateCloudTrailBucketLocal",
         "Properties": {
            "AccessControl": "Private",
            "VersioningConfiguration": {"Status":"Enabled" },
            "BucketName": {
                "Fn::Join" : [ "", [ { "Ref" : "pS3CloudTrailLocal" }, "-",{ "Ref" : "AWS::Region" },"-", { "Ref" : "AWS::AccountId" } ]]
            }
         },
         "DeletionPolicy": "Retain"
      },

        "rCloudTrailS3Policy" : {
          "Type" : "AWS::S3::BucketPolicy",
         "Condition" : "cCreateCloudTrailBucketLocal",
      "DependsOn": "rCloudTrailBucket",
      "Properties" : {
        "Bucket" : { "Ref" : "rCloudTrailBucket" },
        "PolicyDocument": {
                "Statement": [
		    {
      "Sid": "AWSCloudTrailAclCheck20131101",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::903692715234:root",
          "arn:aws:iam::859597730677:root",
          "arn:aws:iam::814480443879:root",
          "arn:aws:iam::216624486486:root",
          "arn:aws:iam::086441151436:root",
          "arn:aws:iam::388731089494:root",
          "arn:aws:iam::284668455005:root",
          "arn:aws:iam::113285607260:root",
          "arn:aws:iam::035351147821:root"
        ]
      },
      "Action": "s3:GetBucketAcl",
      "Resource": [ { "Fn::Join" : [ "", [ "arn:aws:s3:::", { "Ref" : "pS3CloudTrailLocal" }, "-",{ "Ref" : "AWS::Region" },"-", { "Ref" : "AWS::AccountId" } ]] } ]
    },
    {
      "Sid": "AWSCloudTrailWrite20131101",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::903692715234:root",
          "arn:aws:iam::859597730677:root",
          "arn:aws:iam::814480443879:root",
          "arn:aws:iam::216624486486:root",
          "arn:aws:iam::086441151436:root",
          "arn:aws:iam::388731089494:root",
          "arn:aws:iam::284668455005:root",
          "arn:aws:iam::113285607260:root",
          "arn:aws:iam::035351147821:root"
        ]
      },
      "Action": "s3:PutObject",
      "Resource": [ { "Fn::Join" : [ "", [ "arn:aws:s3:::", { "Ref" : "pS3CloudTrailLocal" }, "-",{ "Ref" : "AWS::Region" },"-", { "Ref" : "AWS::AccountId" }, "/AWSLogs/", { "Ref" : "AWS::AccountId" }, "/*" ]] } ],
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Sid" : "Enforce HTTPS Connections",
      "Action": "s3:*",
      "Effect":"Deny",
      "Principal": "*",
      "Resource": [ { "Fn::Join" : [ "", [ "arn:aws:s3:::", { "Ref" : "pS3CloudTrailLocal" }, "-",{ "Ref" : "AWS::Region" },"-", { "Ref" : "AWS::AccountId" }, "/AWSLogs/", { "Ref" : "AWS::AccountId" }, "/*" ]] } ],
      "Condition":{
          "Bool":
          { "aws:SecureTransport": false }
      }
    }
]
         }
                }
        },

    "rCloudTrailLogging" : {
      "Type" : "AWS::CloudTrail::Trail",
"Condition" : "cExistingCloudTrailBucket",
"Properties" : {
        "S3BucketName" : { "Fn::If": ["cCreateCloudTrailBucketLocal",{ "Fn::Join" : [ "", [ { "Ref" : "pS3CloudTrailLocal" },"-",{ "Ref" : "AWS::Region" },"-", { "Ref" : "AWS::AccountId" } ]] }, { "Ref" : "pS3CloudTrailBucketExisting" } ] },
        "IsLogging" : true,
        "EnableLogFileValidation" : true
      }
    },

    "rCloudTrailLoggingLocal" : {
      "Type" : "AWS::CloudTrail::Trail",
	"DependsOn" : "rCloudTrailBucket",
"Condition" : "cCreateCloudTrailBucketLocal",
"Properties" : {
        "S3BucketName" : { "Fn::If": ["cCreateCloudTrailBucketLocal",{ "Fn::Join" : [ "", [ { "Ref" : "pS3CloudTrailLocal" },"-",{ "Ref" : "AWS::Region" },"-", { "Ref" : "AWS::AccountId" } ]] }, { "Ref" : "pS3CloudTrailBucketExisting" } ] },
        "IsLogging" : true,
        "EnableLogFileValidation" : true,
        "CloudWatchLogsLogGroupArn" : { "Fn::GetAtt" : [ "rCloudTrailLogGroup" , "Arn" ] },
        "CloudWatchLogsRoleArn" : { "Fn::GetAtt" : [ "rCloudWatchLogsRole" , "Arn" ] }
      }
    },


      "rCloudTrailRole": {
         "Type": "AWS::IAM::Role",
	 "Condition" : "cCreateCloudTrailBucketLocal",
         "Properties": {
            "AssumeRolePolicyDocument": {
               "Statement": [
                  {
                     "Effect": "Allow",
                     "Principal": {
                        "Service": [
                           "ec2.amazonaws.com"
                        ]
                     },
                     "Action": [
                        "sts:AssumeRole"
                     ]
                  }
               ]
            },
            "Path": "/",
                "Policies" : [ {
                        "PolicyName" : "customsecurityaudit",
                        "PolicyDocument" :
                                {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": [ { "Fn::Join" : [ "", [ "arn:aws:s3:::", "ctrail-",{ "Ref" : "AWS::Region" },"-", { "Ref" : "AWS::AccountId" } ]] } ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": [ { "Fn::Join" : [ "", [ "arn:aws:s3:::", "ctrail-",{ "Ref" : "AWS::Region" },"-", { "Ref" : "AWS::AccountId" }, "/*" ]] } ]
    }
	]
		}
	} ]
	}
      },
      "rCloudTrailProfile": {
         "Type": "AWS::IAM::InstanceProfile",
	 "Condition" : "cCreateCloudTrailBucketLocal",
         "DependsOn": "rCloudTrailRole",
         "Properties": {
            "Path": "/",
            "Roles": [
               {
                  "Ref": "rCloudTrailRole"
               }
            ]
         }
      },
        "rSysAdminRole" : {
                "Type" : "AWS::IAM::Role",
                "Properties" : {
                "AssumeRolePolicyDocument" : {
                     "Statement" : [
                            {
                                "Effect" : "Allow",
                                "Principal" : {
				  "Service": [
                           "ec2.amazonaws.com"
                        ]

                        },
                        "Action" : [
                                "sts:AssumeRole"
                                 ]
                         }
                         ]
                         }
                }
        },


      "rSysAdminProfile": {
         "Type": "AWS::IAM::InstanceProfile",
         "DependsOn": "rSysAdminRole",
         "Properties": {
            "Path": "/",
            "Roles": [
               {
                  "Ref": "rSysAdminRole"
               }
            ]
         }
      },

      "rSysAdmin": {
         "Type": "AWS::IAM::Group",
         "Properties": {
            "Path": "/"
         }
      },

"rSysAdminPolicy" : {
 "Type" : "AWS::IAM::ManagedPolicy",
 "Properties" : {
  "PolicyDocument" :
        {
                     "Version": "2012-10-17",
                     "Statement": [
                        {
                           "Effect": "Allow",
                           "NotAction": "iam:*",
                           "Resource": "*"
                        },
                         {
                                "Effect": "Deny",
                                "Action": "aws-portal:*Billing",
                                "Resource": "*"
                        },
                        {
                                "Effect" : "Deny",
                                "Action" : [ "cloudtrail:DeleteTrail",
                                             "cloudtrail:StopLogging",
                                             "cloudtrail:UpdateTrail" ],
                                "Resource" : "*"
                        }
                     ]
                  },
                  "Roles" : [
                  { "Ref" : "rSysAdminRole" }
                 ],
		  "Groups" : [
		   { "Ref" : "rSysAdmin" }
		]
                 }
        },


      "rIAMAdminGroup": {
         "Type": "AWS::IAM::Group",
         "Properties": {
            "Path": "/"
           }
      },

        "rIAMAdminRole" : {
                "Type" : "AWS::IAM::Role",
                "Properties" : {
                "AssumeRolePolicyDocument" : {
                     "Statement" : [
                            {
                                "Effect" : "Allow",
                                "Principal" : {
                                  "Service": [
                           "ec2.amazonaws.com"
                        ]

                        },
                        "Action" : [
                                "sts:AssumeRole"
                                 ]
                         }
                         ]
                         }
                }
        },

      "rIAMAdminProfile": {
         "Type": "AWS::IAM::InstanceProfile",
         "DependsOn": "rIAMAdminRole",
         "Properties": {
            "Path": "/",
            "Roles": [
               {
                  "Ref": "rIAMAdminRole"
               }
            ]
         }
      },



"rIAMAdminPolicy" : {
 "Type" : "AWS::IAM::ManagedPolicy",
 "Properties" : {
  "PolicyDocument" :
        {
                     "Version": "2012-10-17",
                     "Statement": [
                        {
                           "Effect": "Allow",
                           "Action": "iam:*",
                           "Resource": "*"
                        },
                       {
                                "Effect": "Deny",
                                "Action": "aws-portal:*Billing",
                                "Resource": "*"
                        }

                     ]
                  },
                  "Roles" : [
                  { "Ref" : "rIAMAdminRole" }
                 ],
		  "Groups" : [
		    { "Ref" : "rIAMAdminGroup" }
		 ]
                 }
        },


      "rInstanceOpsGroup": {
         "Type": "AWS::IAM::Group",
         "Properties": {
            "Path": "/"
           }
      },

        "rInstanceOpsRole" : {
                "Type" : "AWS::IAM::Role",
                "Properties" : {
                "AssumeRolePolicyDocument" : {
                     "Statement" : [
                            {
                                "Effect" : "Allow",
                                "Principal" : {
                                  "Service": [
                           "ec2.amazonaws.com"
                        ]

                        },
                        "Action" : [
                                "sts:AssumeRole"
                                 ]
                         }
                         ]
                         }
                }
        },

      "rInstanceOpsProfile": {
         "Type": "AWS::IAM::InstanceProfile",
         "DependsOn": "rIAMAdminRole",
         "Properties": {
            "Path": "/",
            "Roles": [
               {
                  "Ref": "rIAMAdminRole"
               }
            ]
         }
      },


"rInstanceOpsPolicy" : {
 "Type" : "AWS::IAM::ManagedPolicy",
 "Properties" : {
  "PolicyDocument" : {
                                                                "Version": "2012-10-17",
                                        "Statement": [
                                                        {
                                                                "Action": "ec2:*",
                                                                "Effect": "Allow",
                                                                "Resource": "*"
                                                        },
                                                        {
                                                                "Effect": "Allow",
                                                                "Action": "elasticloadbalancing:*",
                                                                "Resource": "*"
                                                        },
                                                        {
                                                                "Effect": "Allow",
                                                                "Action": "cloudwatch:*",
                                                                "Resource": "*"
                                                        },
                                                        {
                                                                "Effect": "Allow",
                                                                "Action": "autoscaling:*",
                                                                "Resource": "*"
                                                        },
                                                        {
                                                                "Effect" : "Deny",
                                                                    "Action":[  "ec2:CreateVpc*",
                                                                                "ec2:DeleteVpc*",
                                                                                "ec2:ModifyVpc*",
                                                                                "ec2:CreateSubnet*",
                                                                                "ec2:DeleteSubnet*",
                                                                                "ec2:ModifySubnet*",
                                                                                "ec2:Create*Route*",
                                                                                "ec2:DeleteRoute*",
                                                                                "ec2:AssociateRoute*",
                                                                                "ec2:ReplaceRoute*",
                                                                                "ec2:CreateVpn*",
                                                                                "ec2:DeleteVpn*",
                                                                                "ec2:AttachVpn*",
                                                                                "ec2:DetachVpn*",
                                                                                "ec2:CreateNetworkAcl*",
                                                                                "ec2:DeleteNetworkAcl*",
                                                                                "ec2:ReplaceNetworkAcl*",
                                                                                "ec2:*Gateway*",
                                                                                "ec2:*PeeringConnection*"
                                                                        ],
                                                                      "Resource" : "*"
                                                        },
                                                               {
                                                                      "Effect": "Deny",
                                                                  "Action": "aws-portal:*Billing",
                                                                 "Resource": "*"
                                                                }
                                                ]

          },
                  "Roles" : [
                  { "Ref" : "rInstanceOpsRole" }
                 ],
		  "Groups" : [
		  { "Ref" : "rInstanceOpsGroup" }
		]
                 }
        },




      "rReadOnlyAdminGroup": {
         "Type": "AWS::IAM::Group",
         "Properties": {
            "Path": "/"
               }
      },


        "rReadOnlyAdminRole" : {
                "Type" : "AWS::IAM::Role",
                "Properties" : {
                "AssumeRolePolicyDocument" : {
                     "Statement" : [
                            {
                                "Effect" : "Allow",
                                "Principal" : {
                                  "Service": [
                           "ec2.amazonaws.com"
                        ]

                        },
                        "Action" : [
                                "sts:AssumeRole"
                                 ]
                         }
                         ]
                         }
                }
        },

      "rReadOnlyAdminProfile": {
         "Type": "AWS::IAM::InstanceProfile",
         "DependsOn": "rReadOnlyAdminRole",
         "Properties": {
            "Path": "/",
            "Roles": [
               {
                  "Ref": "rReadOnlyAdminRole"
               }
            ]
         }
      },

"rReadOnlyAdminPolicy" : {
 "Type" : "AWS::IAM::ManagedPolicy",
 "DependsOn" : "rReadOnlyAdminProfile",
 "Properties" : {
  "PolicyDocument" :
        {
                     "Version": "2012-10-17",
                     "Statement": [
                        {
                           "Action": [
                                                              "appstream:Get*",
                              "autoscaling:Describe*",
                              "cloudformation:DescribeStacks",
                              "cloudformation:DescribeStackEvents",
                              "cloudformation:DescribeStackResource",
                              "cloudformation:DescribeStackResources",
                              "cloudformation:GetTemplate",
                              "cloudformation:List*",
                              "cloudfront:Get*",
                              "cloudfront:List*",
                              "cloudtrail:DescribeTrails",
                              "cloudtrail:GetTrailStatus",
                              "cloudwatch:Describe*",
                              "cloudwatch:Get*",
                              "cloudwatch:List*",
                              "directconnect:Describe*",
                              "dynamodb:GetItem",
                              "dynamodb:BatchGetItem",
                              "dynamodb:Query",
                              "dynamodb:Scan",
                              "dynamodb:DescribeTable",
                              "dynamodb:ListTables",
                              "ec2:Describe*",
                              "elasticache:Describe*",
                              "elasticbeanstalk:Check*",
                              "elasticbeanstalk:Describe*",
                              "elasticbeanstalk:List*",
                              "elasticbeanstalk:RequestEnvironmentInfo",
                              "elasticbeanstalk:RetrieveEnvironmentInfo",
                              "elasticloadbalancing:Describe*",
                              "elastictranscoder:Read*",
                              "elastictranscoder:List*",
                              "iam:List*",
                              "iam:Get*",
                              "kinesis:Describe*",
                              "kinesis:Get*",
                              "kinesis:List*",
                              "opsworks:Describe*",
                              "opsworks:Get*",
                              "route53:Get*",
                              "route53:List*",
                              "redshift:Describe*",
                              "redshift:ViewQueriesInConsole",
                              "rds:Describe*",
                              "rds:ListTagsForResource",
                              "s3:Get*",
                              "s3:List*",
                              "sdb:GetAttributes",
                              "sdb:List*",
                              "sdb:Select*",
                              "ses:Get*",
                              "ses:List*",
                              "sns:Get*",
                              "sns:List*",
                              "sqs:GetQueueAttributes",
                              "sqs:ListQueues",
                              "sqs:ReceiveMessage",
                              "storagegateway:List*",
                              "storagegateway:Describe*",
                              "trustedadvisor:Describe*"
                           ],
                           "Effect": "Allow",
                           "Resource": "*"
                        },
                        {
                                "Effect": "Deny",
                                "Action": "aws-portal:*Billing",
                                "Resource": "*"
                        }
                     ]

                  },
                  "Roles" : [
                  { "Ref" : "rReadOnlyAdminRole" }
                 ],
                  "Groups" : [
                    { "Ref" : "rReadOnlyAdminGroup" }
                 ]
                 }
        },

      "rReadOnlyBillingGroup": {
         "Type": "AWS::IAM::Group",
         "Properties": {
            "Path": "/"
               }
      },
      "rSecurityAlarmTopic": {
  "Type": "AWS::SNS::Topic",
  "Properties": {
      "Subscription": [
          {
              "Endpoint": { "Ref": "pNotifyEmail" },
              "Protocol": "email"
          }
      ]
  }
},
      "rIAMPolicyChangesMetricFilter": {
"Type": "AWS::Logs::MetricFilter",
"Condition" : "cCreateCloudTrailBucketLocal",
"Properties": {
    "LogGroupName": { "Ref" : "rCloudTrailLogGroup" },
    "FilterPattern": "{($.eventName=*User)||($.eventName=*Group)||($.eventName=*Role)||($.eventName=*Policy)}",
    "MetricTransformations": [
        {
            "MetricNamespace": "CloudTrailMetrics",
            "MetricName": "IAMPolicyEventCount",
            "MetricValue": "1"
        }
    ]
}
},
"rIAMPolicyChangesAlarm": {
"Type": "AWS::CloudWatch::Alarm",
"Properties": {
    "AlarmName" : "CloudTrailIAMPolicyChanges",
    "AlarmDescription" : "IAM configuration changes detected!",
    "AlarmActions" : [{ "Ref" : "rSecurityAlarmTopic" }],
    "MetricName" : "IAMPolicyEventCount",
    "Namespace" : "CloudTrailMetrics",
    "ComparisonOperator" : "GreaterThanOrEqualToThreshold",
    "EvaluationPeriods" : "1",
    "Period" : "300",
    "Statistic" : "Sum",
    "Threshold" : "1"
}
},
"rIAMRootActivity": {
"Type": "AWS::Logs::MetricFilter",
"Condition" : "cCreateCloudTrailBucketLocal",
"Properties": {
		"LogGroupName": { "Ref" : "rCloudTrailLogGroup" },
		"FilterPattern": "{($.userIdentity=root)}",
		"MetricTransformations": [
				{
						"MetricNamespace": "CloudTrailMetrics",
						"MetricName": "RootUserPolicyEventCount",
						"MetricValue": "1"
				}
		]
  }
},
"rRootActivityAlarm": {
		"Type": "AWS::CloudWatch::Alarm",
		"Properties": {
				"AlarmName" : "CloudTrailIAMRootActivity",
				"AlarmDescription" : "Root user activity detected!",
				"AlarmActions" : [{ "Ref" : "rSecurityAlarmTopic" }],
				"MetricName" : "RootUserPolicyEventCount",
				"Namespace" : "CloudTrailMetrics",
				"ComparisonOperator" : "GreaterThanOrEqualToThreshold",
				"EvaluationPeriods" : "1",
				"Period" : "300",
				"Statistic" : "Sum",
				"Threshold" : "1"
		}
},


      "rCloudTrailLogGroup" : {
    			"Type" : "AWS::Logs::LogGroup",
          "Condition" : "cCreateCloudTrailBucketLocal",
  				"Properties" : {
  						"RetentionInDays" : "90"
  				}
  		},
      "rCloudWatchLogsRole": {
    		 "Type": "AWS::IAM::Role",
         "Condition" : "cCreateCloudTrailBucketLocal",
    		 "Properties": {
    				"AssumeRolePolicyDocument": {
    					 "Statement": [
    							{
    								 "Effect": "Allow",
    								 "Principal": {
    										"Service": [
    											 "cloudtrail.amazonaws.com"
    										]
    								 },
    								 "Action": [
    										"sts:AssumeRole"
    								 ]
    							}
    					 ]
    				},
    				"Path": "/",
    						"Policies" : [ {
    										"PolicyName" : "cloudwatchlogsrole",
    										"PolicyDocument" :
    										{
    										  "Version": "2012-10-17",
    										  "Statement": [
    										    {
    										      "Sid": "AWSCloudTrailCreateLogStream20141101",
    										      "Effect": "Allow",
    										      "Action": [
    										        "logs:CreateLogStream"
    										      ],
    										      "Resource": [
    														{ "Fn::Join" : [ "", [ "arn:aws:logs:",{ "Ref" : "AWS::Region" },":",{ "Ref" : "AWS::AccountId" },":log-group:",{ "Ref" : "rCloudTrailLogGroup" },":log-stream:*" ] ] }
    										      ]
    										    },
    										    {
    										      "Sid": "AWSCloudTrailPutLogEvents20141101",
    										      "Effect": "Allow",
    										      "Action": [
    										        "logs:PutLogEvents"
    										      ],
    										      "Resource": [
    														{ "Fn::Join" : [ "", [ "arn:aws:logs:",{ "Ref" : "AWS::Region" },":",{ "Ref" : "AWS::AccountId" },":log-group:",{ "Ref" : "rCloudTrailLogGroup" },":log-stream:*" ] ] }
    										      ]
    										    }
    										  ]
    										}

    } ]
    }
    	},


"rReadOnlyBillingPolicy" : {
 "Type" : "AWS::IAM::ManagedPolicy",
 "Properties" : {
  "PolicyDocument" :
                                {
                                        "Version": "2012-10-17",
                                        "Statement": [
                                                {
                                                        "Effect": "Allow",
                                                        "Action": "aws-portal:View*",
                                                        "Resource": "*"
                                                },
                                                {
                                                        "Effect": "Deny",
                                                        "Action": "aws-portal:*Account",
                                                        "Resource": "*"
                                                }
                                        ]
                                },

                  "Groups" : [
                  { "Ref" : "rReadOnlyBillingGroup" }
                 ]
                 }
        }


   },
   "Outputs": {
      "rCloudTrailRole": {
         "Value": {
		            "Fn::If" : [ "cCreateCloudTrailBucketLocal", { "Ref" : "rCloudTrailRole" },"N/A"]
         }
      },
      "rCloudTrailProfile": {
         "Value": {
            "Fn::If" : [ "cCreateCloudTrailBucketLocal", { "Ref" : "rCloudTrailProfile" },"N/A"]
         }
      },
      "rSysAdmin": {
         "Value": {
            "Ref": "rSysAdmin"
         }
      },
      "rIAMAdminGroup": {
         "Value": {
            "Ref": "rIAMAdminGroup"
         }
      },
      "rInstanceOpsGroup" : {
         "Value": {
            "Ref": "rInstanceOpsGroup"
         }
      },
      "rReadOnlyBillingGroup" : {
	 "Value" : {
	    "Ref" : "rReadOnlyBillingGroup"
	 }
      },
      "rReadOnlyAdminGroup": {
         "Value": {
            "Ref": "rReadOnlyAdminGroup"
         }
      }
   }
}
