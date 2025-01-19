import { core, platform } from "@winglang/sdk";
import { PulumiApp } from "./app";
import { PulumiBucket } from "./bucket";
import { PulumiFunction } from "./function";
import { PulumiQueue } from "./queue";

export class Platform implements platform.IPlatform {
  target = "pulumi";

  public newApp(props: core.AppProps): core.App {
    return new PulumiApp(props);
  }

  public resolveType(type: string): any {
    if (type === "@winglang/sdk.cloud.Bucket") {
      return PulumiBucket;
    }

    if (type === "@winglang/sdk.cloud.Function") {
      return PulumiFunction;
    }

    if (type === "@winglang/sdk.cloud.Queue") {
      return PulumiQueue;
    }

    return undefined;
  }
};
