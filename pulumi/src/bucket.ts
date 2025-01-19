import { cloud } from "@winglang/sdk";
import { Construct } from "constructs";
import { PulumiResource } from "./resource";
import { HttpMethod } from "@winglang/sdk/lib/cloud/api";
import { AwsBucket } from "./aws/bucket";

export class PulumiBucket extends AwsBucket {
  public readonly bucket: PulumiResource;

  constructor(scope: Construct, id: string, props: cloud.BucketProps = {}) {
    super(scope, id, props);

    const p: Record<string, any> = {};

    if (props.forceDestroy ?? false) {
      p.forceDestroy = true;
    }

    this.bucket = new PulumiResource(this, id, {
      type: "aws:s3:BucketV2",
      properties: p,
    });

    if (props.cors ?? false) {
      const options = props.corsOptions;
      new PulumiResource(this, "BucketCorsConfigurationV2", {
        type: "aws:s3:BucketCorsConfigurationV2",
        properties: {
          bucket: this.bucket.ref,
          corsRules: [
            {
              allowedHeaders: options?.allowedHeaders ?? ["Content-Type", "Authorization"],
              allowedMethods: options?.allowedMethods ?? [HttpMethod.GET, HttpMethod.POST, HttpMethod.PUT, HttpMethod.DELETE, HttpMethod.HEAD],
              allowedOrigins: options?.allowedOrigins ?? ["*"],
              exposeHeaders: options?.exposeHeaders ?? [],
              maxAgeSeconds: options?.maxAge?.seconds ?? 300,
            }
          ]
        }
      });
    }

    if (props.public ?? false) {
      const bucketOwnershipControls = new PulumiResource(this, "BucketOwnershipControls", {
        type: "aws:s3:BucketOwnershipControls",
        properties: {
          bucket: this.bucket.ref,
          rule: {
            objectOwnership: "BucketOwnerPreferred",
          }
        }
      });

      const bucketPublicAccessBlock = new PulumiResource(this, "BucketPublicAccessBlock", {
        type: "aws:s3:BucketPublicAccessBlock",
        properties: {
          bucket: this.bucket.ref,
          blockPublicAcls: false,
          blockPublicPolicy: false,
          ignorePublicAcls: false,
          restrictPublicBuckets: false,
        }
      });

      new PulumiResource(this, "Acl", {
        type: "aws:s3:BucketAclV2",
        options: {
          dependsOn: [
            bucketOwnershipControls.self,
            bucketPublicAccessBlock.self,
          ]
        },
        properties: {
          bucket: this.bucket.ref,
          acl: "public-read",
        }
      });
    }
  }

  public get bucketArn() {
    return this.bucket.attr("arn");
  }

  public get bucketName() {
    return this.bucket.attr("id");
  }

  public get bucketDomainName() {
    return this.bucket.attr("bucketDomainName");
  }

  public addObject(path: string, content: string): void {
    new PulumiResource(this, "BucketObject", {
      type: "aws:s3:BucketObjectv2",
      properties: {
        bucket: this.bucket.ref,
        key: path,
        content: content,
      }
    });
  }

  public addCorsRule(value: cloud.BucketCorsOptions): void {
    new PulumiResource(this, "BucketCorsConfigurationV2", {
      type: "aws:s3:BucketCorsConfigurationV2",
      properties: {
        bucket: this.bucket.ref,
        corsRules: {
          allowedHeaders: value.allowedHeaders,
          allowedMethods: value.allowedMethods,
          allowedOrigins: value.allowedOrigins,
          exposeHeaders: value.exposeHeaders,
          maxAgeSeconds: value.maxAge?.seconds,
        },
      }
    });
  }

  protected createTopicHandler(eventType: cloud.BucketEventType, inflight: cloud.IBucketEventHandler): cloud.ITopicOnMessageHandler {
    throw new Error("Method not implemented.");
  }
}
