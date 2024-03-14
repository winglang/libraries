bring cloud;
bring aws;
bring "cdktf" as cdktf;
bring "@cdktf/provider-aws" as tfaws;
bring "./dynamodb-types.w" as dynamodb_types;
bring "./dynamodb-client.w" as dynamodb_client;

struct DynamoDBStreamEventDynamoDB {
  ApproximateCreationDateTime: str;
  Keys: Json?;
  NewImage: Json?;
  OldImage: Json?;
  SequenceNumber: str;
  SizeBytes: num;
  StreamViewType: str;
}

struct DynamoDBStreamEventRecord {
  eventID: str;
  eventName: str;
  dynamodb: DynamoDBStreamEventDynamoDB;
}

struct DynamoDBStreamEvent {
  Records: Array<DynamoDBStreamEventRecord>;
}

class Util {
  extern "./dynamodb.mjs" pub inflight static unmarshall(
    item: Json,
    options: Json?,
  ): Json;

  pub inflight static safeUnmarshall(item: Json?, options: Json?): Json? {
    if item? {
      return Util.unmarshall(item, options);
    }
    return nil;
  }
}

pub class Table_tfaws impl dynamodb_types.ITable {
  tableName: str;
  table: tfaws.dynamodbTable.DynamodbTable;

  new(props: dynamodb_types.TableProps) {
    this.table = new tfaws.dynamodbTable.DynamodbTable({
      name: "{this.node.path.replaceAll("/", "-").substring(21, (255+21)-9)}-{this.node.addr.substring(42-8)}",
      attribute: props.attributes,
      hashKey: props.hashKey,
      rangeKey: props.rangeKey,
      billingMode: "PAY_PER_REQUEST",
      streamEnabled: true,
      streamViewType: "NEW_AND_OLD_IMAGES",
    });

    this.tableName = this.table.name;
  }

  pub connection(): dynamodb_types.Connection {
    return {
      endpoint: nil,
      tableName: this.tableName,
    };
  }

  pub setStreamConsumer(handler: inflight (dynamodb_types.StreamRecord): void) {
    let consumer = new cloud.Function(inflight (eventStr) => {
      let event: DynamoDBStreamEvent = unsafeCast(eventStr);
      for record in event.Records {
        handler({
          eventID: record.eventID,
          eventName: record.eventName,
          dynamodb: {
            ApproximateCreationDateTime: record.dynamodb.ApproximateCreationDateTime,
            Keys: Util.safeUnmarshall(record.dynamodb.Keys, {
              wrapNumbers: true,
            }),
            NewImage: Util.safeUnmarshall(record.dynamodb.NewImage, {
              wrapNumbers: true,
            }),
            OldImage: Util.safeUnmarshall(record.dynamodb.OldImage, {
              wrapNumbers: true,
            }),
            SequenceNumber: record.dynamodb.SequenceNumber,
            SizeBytes: record.dynamodb.SizeBytes,
            StreamViewType: record.dynamodb.StreamViewType,
          },
        });
      }
    });

    if let lambda = aws.Function.from(consumer) {
      lambda.addPolicyStatements({
        actions: [
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams",
        ],
        effect: aws.Effect.ALLOW,
        resources: [
          this.table.streamArn,
        ],
      });

      new tfaws.lambdaEventSourceMapping.LambdaEventSourceMapping(
        {
          eventSourceArn: this.table.streamArn,
          functionName: lambda.functionName,
          startingPosition: "LATEST",
        },
      );
    }
  }

  pub onLift(host: std.IInflightHost, ops: Array<str>) {
    if let lambda = aws.Function.from(host) {
      let actions = MutArray<str>[];
      if ops.contains("delete") {
        actions.push("dynamodb:DeleteItem");
      }
      if ops.contains("get") {
        actions.push("dynamodb:GetItem");
      }
      if ops.contains("put") {
        actions.push("dynamodb:PutItem");
      }
      if ops.contains("scan") {
        actions.push("dynamodb:Scan");
      }
      if ops.contains("query") {
        actions.push("dynamodb:Query");
      }
      if ops.contains("transactWrite") {
        actions.push(
          "dynamodb:ConditionCheckItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
        );
      }
      if ops.length > 0 {
        lambda.addPolicyStatements({
          actions: actions.copy(),
          effect: aws.Effect.ALLOW,
          resources: [
            this.table.arn,
          ],
        });
      }
    }
  }

  inflight client: dynamodb_types.IClient;

  inflight new() {
    this.client = new dynamodb_client.Client(
      tableName: this.tableName,
    );
  }

  pub inflight delete(options: dynamodb_types.DeleteOptions): dynamodb_types.DeleteOutput {
    return this.client.delete(options);
  }

  pub inflight get(options: dynamodb_types.GetOptions): dynamodb_types.GetOutput {
    return this.client.get(options);
  }

  pub inflight put(options: dynamodb_types.PutOptions): dynamodb_types.PutOutput {
    return this.client.put(options);
  }

  pub inflight transactWrite(options: dynamodb_types.TransactWriteOptions): dynamodb_types.TransactWriteOutput {
    return this.client.transactWrite(options);
  }

  pub inflight scan(options: dynamodb_types.ScanOptions?): dynamodb_types.ScanOutput {
    return this.client.scan(options);
  }

  pub inflight query(options: dynamodb_types.QueryOptions): dynamodb_types.QueryOutput {
    return this.client.query(options);
  }
}
