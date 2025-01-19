import { cloud } from "@winglang/sdk";
import { createBundle } from "@winglang/sdk/lib/shared/bundling";
import { Construct } from "constructs";
import { PulumiResource, PulumiVariable } from "./resource";
import { writeFileSync } from "fs";
import { externalLibraries, NetworkConfig, PolicyStatement } from "@winglang/sdk/lib/shared-aws";
import { join } from "path";
import { AwsFunction } from "./aws/function";

export class PulumiFunction extends AwsFunction {
  private readonly fn: PulumiResource;
  private readonly policy: PolicyStatement[] = [];
  private readonly environment: Record<string, string>;

  constructor(scope: Construct, id: string, private readonly inflight: cloud.IFunctionHandler, private readonly props: cloud.FunctionProps = {}) {
    super(scope, id, inflight, props);

    const inflightCodeApproximation = this._getCodeLines(this.inflight).join("\n");
    writeFileSync(this.entrypoint, inflightCodeApproximation);

    const bundle = createBundle(this.entrypoint, externalLibraries);

    this.environment = {
      NODE_OPTIONS: "--enable-source-maps",
      ...this.env,
    };

    const assumeRole = new PulumiVariable(this, "AssumeRole", {
      "fn::invoke": {
        function: "aws:iam:getPolicyDocument",
        arguments: {
          statements: [{
            effect: "Allow",
            principals: [{
              type: "Service",
              identifiers: ["lambda.amazonaws.com"]
            }],
            actions: ["sts:AssumeRole"]
          }]
        }
      }
    })

    const policy = new PulumiVariable(this, "Policy", {
      "fn::invoke": {
        function: "aws:iam:getPolicyDocument",
        arguments: {
          statements: this.policy
        }
      }
    });

    const role = new PulumiResource(this, "Role", {
      type: "aws:iam:Role", 
      properties: {
        assumeRolePolicy: assumeRole.attr("json"),
        managedPolicyArns: [
          "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        ],
        inlinePolicies: [{
          name: "lambda-policy",
          policy: policy.attr("json")
        }],
      }
    });

    const assetPath = "handler.zip";

    const asset = new PulumiVariable(this, "Asset", {
      "fn::invoke": {
        function: "archive:getFile",
        arguments: {
          type: "zip",
          sourceFile: join(bundle.directory, "index.cjs"),
          outputPath: assetPath,
        }
      }
    });

    this.fn = new PulumiResource(this, "Function", {
      type: "aws:lambda:Function",
      properties: {
        role: role.attr("arn"),
        handler: "index.handler",
        code: { "fn::fileArchive": assetPath },
        sourceCodeHash: asset.attr("outputBase64sha256"),
        runtime: "nodejs20.x",
        timeout: this.props.timeout ? this.props.timeout.seconds : 60,
        memorySize: this.props.memory ?? 1024,
        architectures: ["x86_64"],
        environment: {
          variables: this.environment
        }
      }
    });
    
  }

  public addEnvironment(name: string, value: string): void {
    super.addEnvironment(name, value);
    this.environment[name] = value;
  }

  /**
   * Add a Lambda layer to the function.
   * @param layerArn The ARN of the layer.
   */
  public addLambdaLayer(layerArn: string): void {
    throw new Error("Method not implemented.");
  }

  public get functionArn() {
    return this.fn.attr("arn");
  }

  public get functionName() {
    return this.fn.attr("id");
  }
 
  public addPolicyStatements(...policies: PolicyStatement[]): void {
    this.policy.push(...policies);
  }

  public addNetwork(config: NetworkConfig): void {
    throw new Error("Method not implemented.");
  }
}