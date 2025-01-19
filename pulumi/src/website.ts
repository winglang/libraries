import { AwsWebsite } from "./aws/website";
import { Construct } from "@winglang/sdk/lib/core/types";
import { WebsiteProps } from "@winglang/sdk/lib/cloud";

export class PulumiWebsite extends AwsWebsite {
  constructor(scope: Construct, id: string, props: WebsiteProps) {
    super(scope, id, props);

    
  }

  public get url(): string {
    throw new Error("Method not implemented.");
  }
  public get bucketArn(): string {
    throw new Error("Method not implemented.");
  }
  public get bucketName(): string {
    throw new Error("Method not implemented.");
  }

}