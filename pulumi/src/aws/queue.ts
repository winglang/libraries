import { QueueProps } from "@winglang/sdk/lib/cloud";
import { AwsInflightHost, Effect, Function, IAwsFunction, IAwsQueue, Queue, QueueSetConsumerHandler } from "@winglang/sdk/lib/shared-aws";
import { Construct } from "constructs";
import { Duration, Node } from "@winglang/sdk/lib/std";
import { cloud, std } from "@winglang/sdk";
import { App, InflightClient, LiftMap } from "@winglang/sdk/lib/core";
import { calculateQueuePermissions } from "@winglang/sdk/lib/shared-aws/permissions";
import { IInflightHost } from "@winglang/sdk/lib/std";

export abstract class AwsQueue extends cloud.Queue implements IAwsQueue {
  /** @internal */
  public static _toInflightType(): string {
    return InflightClient.forType(
      require.resolve("@winglang/sdk/lib/shared-aws/queue.inflight"),
      "QueueClient"
    );
  }

  private readonly queueTimeout: number;  

  constructor(scope: Construct, id: string, props: QueueProps = {}) {
    super(scope, id, props);

    this.queueTimeout = props.timeout?.seconds ?? 30;
  }

  public abstract get queueArn(): string;
  public abstract get queueName(): string;
  public abstract get queueUrl(): string;


  public onLift(host: IInflightHost, ops: string[]): void {
    host.addEnvironment(this.queueUrlEnv, this.queueUrl);

    if (AwsInflightHost.isAwsInflightHost(host)) {
      host.addPolicyStatements(...calculateQueuePermissions(this.queueArn, ops));
    }

    super.onLift(host, ops);
  }

  protected abstract addEventSourceMapping(mapping: EventSourceMappingOptions): void;

  public setConsumer(
    inflight: cloud.IQueueSetConsumerHandler,
    props: cloud.QueueSetConsumerOptions = {}
  ): cloud.Function {
    const functionHandler = QueueSetConsumerHandler.toFunctionHandler(inflight);

    const cfn = new cloud.Function(
      this,
      App.of(this).makeId(this, "Consumer"),
      functionHandler,
      {
        ...props,
        timeout: Duration.fromSeconds(this.queueTimeout),
      }
    );

    const fn = Function.from(cfn);
    if (!fn) {
      throw new Error("Expecting cloud.Function to satisfy IAwsFunction");
    }

    this.addEventSourceMapping({
      consumerFunction: fn,
      batchSize: props.batchSize ?? 1,
      functionResponseTypes: ["ReportBatchItemFailures"],
    });

    fn.addPolicyStatements({
      effect: Effect.ALLOW,
      actions: [
        "sqs:ReceiveMessage",
        "sqs:ChangeMessageVisibility",
        "sqs:GetQueueUrl",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
      ],
      resources: [this.queueArn],
    });

    Node.of(this).addConnection({
      source: this,
      sourceOp: cloud.QueueInflightMethods.PUSH,
      target: fn,
      targetOp: cloud.FunctionInflightMethods.INVOKE,
      name: "consumer",
    });

    return cfn;
  }

  /** @internal */
  public get _liftMap(): LiftMap {
    return {
      [cloud.QueueInflightMethods.PUSH]: [],
      [cloud.QueueInflightMethods.PURGE]: [],
      [cloud.QueueInflightMethods.APPROX_SIZE]: [],
      [cloud.QueueInflightMethods.POP]: [],
    };
  }

  private get queueUrlEnv() {
    return `QUEUE_URL_${this.node.addr}`;
  }

  /** @internal */
  public _liftedState(): Record<string, string> {
    return {
      $queueUrlOrArn: `process.env["${this.queueUrlEnv}"]`,
      $constructPath: `"${this.node.path}"`,
    };
  }
}

export interface EventSourceMappingOptions {
  consumerFunction: IAwsFunction;
  batchSize: number;
  functionResponseTypes: string[];
}