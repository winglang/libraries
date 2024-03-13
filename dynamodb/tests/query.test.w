bring cloud;
bring "../dynamodb.w" as dynamodb;

let table = new dynamodb.Table(
  attributes: [
    {
      name: "id",
      type: "S",
    },
    {
      name: "sk",
      type: "S",
    },
  ],
  hashKey: "id",
  rangeKey: "sk",
) as "query table";

test "query" {
  table.put(
    item: {
      id: "1",
      sk: "a",
      body: "hello a",
    },
  );
  table.put(
    item: {
      id: "2",
      sk: "a",
      body: "hello a",
    },
  );
  table.put(
    item: {
      id: "1",
      sk: "b",
      body: "hello b",
    },
  );

  let response = table.query(
    keyConditionExpression: "id = :id",
    expressionAttributeValues: {":id": "1"},
  );
  assert(response.count == 2);
  assert(response.items.at(0).get("id").asStr() == "1");
  assert(response.items.at(0).get("sk").asStr() == "a");
  assert(response.items.at(0).get("body").asStr() == "hello a");
  assert(response.items.at(1).get("id").asStr() == "1");
  assert(response.items.at(1).get("sk").asStr() == "b");
  assert(response.items.at(1).get("body").asStr() == "hello b");
}
