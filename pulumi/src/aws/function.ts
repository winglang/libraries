import { cloud } from "@winglang/sdk";
import { createBundle } from "@winglang/sdk/lib/shared/bundling";
import { externalLibraries, IAwsFunction, NetworkConfig, PolicyStatement } from "@winglang/sdk/lib/shared-aws";
import { InflightClient } from "@winglang/sdk/lib/core/inflight";
import { LiftMap } from "@winglang/sdk/lib/core";

export abstract class AwsFunction extends cloud.Function implements IAwsFunction {
  /** @internal */
  public static _toInflightType(): string {
    return InflightClient.forType(
      require.resolve("@winglang/sdk/lib/shared-aws/function.inflight"),
      "FunctionClient"
    );
  }

  public abstract get functionArn(): string;
  public abstract get functionName(): string;
  public abstract addLambdaLayer(layerArn: string): void;
  public abstract addPolicyStatements(...policies: PolicyStatement[]): void;
  public abstract addNetwork(config: NetworkConfig): void;

  /** @internal */
  public _preSynthesize(): void {
    super._preSynthesize();

    // re-bundle the function
    createBundle(this.entrypoint, externalLibraries);
  }
  
  /** @internal */
  public get _liftMap(): LiftMap {
    return {
      [cloud.BucketInflightMethods.DELETE]: [],
      [cloud.BucketInflightMethods.GET]: [],
      [cloud.BucketInflightMethods.GET_JSON]: [],
      [cloud.BucketInflightMethods.LIST]: [],
      [cloud.BucketInflightMethods.PUT]: [],
      [cloud.BucketInflightMethods.PUT_JSON]: [],
      [cloud.BucketInflightMethods.PUBLIC_URL]: [],
      [cloud.BucketInflightMethods.EXISTS]: [],
      [cloud.BucketInflightMethods.TRY_GET]: [],
      [cloud.BucketInflightMethods.TRY_GET_JSON]: [],
      [cloud.BucketInflightMethods.TRY_DELETE]: [],
      [cloud.BucketInflightMethods.SIGNED_URL]: [],
      [cloud.BucketInflightMethods.METADATA]: [],
      [cloud.BucketInflightMethods.COPY]: [],
      [cloud.BucketInflightMethods.RENAME]: [],
    };
  }
}
