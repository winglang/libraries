import { cloud } from "@winglang/sdk";
import { InflightClient } from "@winglang/sdk/lib/core/inflight";
import { IInflightHost } from "@winglang/sdk/lib/std";
import { AwsInflightHost, IAwsBucket } from "@winglang/sdk/lib/shared-aws";
import { calculateBucketPermissions } from "@winglang/sdk/lib/shared-aws/permissions";

export abstract class AwsBucket extends cloud.Bucket implements IAwsBucket {
  /** @internal */
  public static _toInflightType(): string {
    return InflightClient.forType(
      require.resolve("@winglang/sdk/lib/shared-aws/bucket.inflight"),
      "BucketClient"
    );
  }

  public abstract get bucketArn(): string;
  public abstract get bucketName(): string;
  public abstract get bucketDomainName(): string;

  public abstract addObject(path: string, content: string): void;
  public abstract addCorsRule(value: cloud.BucketCorsOptions): void;
  protected abstract createTopicHandler(eventType: cloud.BucketEventType, inflight: cloud.IBucketEventHandler): cloud.ITopicOnMessageHandler;

  public onLift(host: IInflightHost, ops: string[]): void {
    host.addEnvironment(this.bucketNameEnv, this.bucketName);

    if (AwsInflightHost.isAwsInflightHost(host)) {
      host.addPolicyStatements(...calculateBucketPermissions(this.bucketArn, ops));
    }

    super.onLift(host, ops);
  }

  /** @internal */
  public _liftedState(): Record<string, string> {
    return {
      $bucketName: `process.env["${this.bucketNameEnv}"]`,
      $constructPath: `"${this.node.path}"`,
    };
  }

  private get bucketNameEnv() {
    return `BUCKET_${this.node.addr}`;
  }
}

