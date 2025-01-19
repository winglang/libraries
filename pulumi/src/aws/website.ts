import { cloud } from "@winglang/sdk";
import { aws } from "@winglang/sdk";

export abstract class AwsWebsite extends cloud.Website implements aws.IAwsWebsite {
  private endpoint: cloud.Endpoint | undefined;

  protected get _endpoint(): cloud.Endpoint {
    if (!this.endpoint) {
      this.endpoint = new cloud.Endpoint(this, "Endpoint", this.url, {
        label: `Website ${this.node.path}`,
        browserSupport: true,
      });
    }

    return this.endpoint;
  }

  public abstract get url(): string;
  public abstract get bucketArn(): string;
  public abstract get bucketName(): string;
}