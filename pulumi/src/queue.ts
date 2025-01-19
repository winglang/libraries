import { QueueProps } from "@winglang/sdk/lib/cloud";
import { PulumiResource } from "./resource";
import { Queue } from "@winglang/sdk/lib/shared-aws";
import { Construct } from "constructs";
import { AwsQueue, EventSourceMappingOptions } from "./aws/queue";

export class PulumiQueue extends AwsQueue {
  public readonly queue: PulumiResource;
  private timeout: number;

  constructor(scope: Construct, id: string, props: QueueProps = {}) {
    super(scope, id);

    this.timeout = props.timeout?.seconds ?? 30;

    const p: Record<string, any> = {
      visibilityTimeoutSeconds: this.timeout,
      messageRetentionSeconds: props.retentionPeriod?.seconds,
    };

    if (props.dlq) {
      const awsQueue = Queue.from(props.dlq.queue);
      if (!awsQueue) {
        throw new Error("DLQ must be an AWS queue");
      }

      p.redrivePolicy = {
        "fn::toJSON": {
          deadLetterTargetArn: awsQueue.queueArn,
          maxReceiveCount: props.dlq.maxDeliveryAttempts || 1,
        }
      }
    }
  
    this.queue = new PulumiResource(this, "Queue", {
      type: "aws:sqs:Queue",
      properties: p
    });
  }

  public get queueArn(): string {
    return this.queue.attr("arn");
  }

  public get queueName(): string {
    return this.queue.attr("id");
  }

  public get queueUrl(): string {
    return this.queue.attr("url");
  }

  protected addEventSourceMapping(mapping: EventSourceMappingOptions): void {
    new PulumiResource(this, "EventSourceMapping", {
      type: "aws:lambda:EventSourceMapping",
      properties: {
        eventSourceArn: this.queueArn,
        functionName: mapping.consumerFunction.functionName,
        batchSize: mapping.batchSize,
        functionResponseTypes: ["ReportBatchItemFailures"],
      },
    });
  }
}
