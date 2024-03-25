bring cloud;
bring aws;
bring "./../../types.w" as types;
bring "../aws/publish.w" as awsUtils;
bring "cdktf" as cdktf;
bring "@cdktf/provider-aws" as tfAws;

pub class Bus impl types.IBus {
  busName: str;
  busArn: str;

  new(props: types.BusProps?) {
    let app = nodeof(this).app;
    // TODO: use typed properties when its available
    if let eventBridgeName = app.parameters.value("eventBridgeName") {
      let bus = new tfAws.dataAwsCloudwatchEventBus.DataAwsCloudwatchEventBus(
        name: eventBridgeName,
      ) as "EventBridge";
      this.busName = bus.name;
      this.busArn = bus.arn;
    } else {
      let bus = new tfAws.cloudwatchEventBus.CloudwatchEventBus(name: props?.name ?? "eventbridge-{this.node.addr.substring(0, 8)}") as "EventBridge";
      this.busName = bus.name;
      this.busArn = bus.arn;
    }
  }

  pub onEvent(name: str, handler: inflight (types.Event): void, pattern: Json): void {
    let rule = new tfAws.cloudwatchEventRule.CloudwatchEventRule(
      name: name,
      eventBusName: this.busName,
      eventPattern: Json.stringify(pattern),
    ) as name;

    // event will be json of type `types.Event`
    let funk = new cloud.Function(inflight (event) => {
      // since wing structs don't supoort custom serialization we need to do it manually
      let json: MutJson = unsafeCast(event);
      json.set("detailType", json.tryGet("detail-type") ?? "");
      handler(unsafeCast(event));
    });

    let awsHandler = aws.Function.from(funk);
    let target = new tfAws.cloudwatchEventTarget.CloudwatchEventTarget(
      rule: rule.name,
      arn: awsHandler?.functionArn!,
      eventBusName: this.busName,
    ) as "{name}-target";

    new tfAws.lambdaPermission.LambdaPermission(
      statementId: "AllowExecutionFromEventBridge",
      action: "lambda:InvokeFunction",
      principal: "events.amazonaws.com",
      sourceArn: rule.arn,
      functionName: awsHandler?.functionName!,
    ) as "{name}-permission";
  }

  pub subscribeQueue(name: str, queue: cloud.Queue, pattern: Json): void {
    let awsQueue = aws.Queue.from(queue);

    let rule = new tfAws.cloudwatchEventRule.CloudwatchEventRule(
      name: name,
      eventBusName: this.busName,
      eventPattern: Json.stringify(pattern),
    ) as name;

    let target = new tfAws.cloudwatchEventTarget.CloudwatchEventTarget(
      rule: rule.name,
      arn: awsQueue?.queueArn!,
      eventBusName: this.busName,
    ) as "{name}-target";

    let queuePolicyDocument = new tfAws.dataAwsIamPolicyDocument.DataAwsIamPolicyDocument(
      statement: {
        effect: "Allow",
        actions: ["sqs:SendMessage"],
        resources: [awsQueue?.queueArn],
        principals: {
          type: "Service",
          identifiers: ["events.amazonaws.com"],
        },
      }
    ) as "{name}-policy-document";

    new tfAws.sqsQueuePolicy.SqsQueuePolicy(
      queueUrl: awsQueue?.queueUrl!,
      policy: queuePolicyDocument.json,
    ) as "{name}-policy";
  }

  pub inflight putEvents(events: Array<types.PublishEvent>): void {
    let name = this.busName;
    awsUtils.putEvent(name, events);
  }

  pub onLift(host: std.IInflightHost, ops: Array<str>) {
    if let host = aws.Function.from(host) {
      if ops.contains("putEvents") {
        host.addPolicyStatements(aws.PolicyStatement {
          actions: ["events:PutEvents"],
          resources: [this.busArn],
        });
      }
    }
  }
}
