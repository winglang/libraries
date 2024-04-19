bring cloud;
bring util;
bring ex;
bring "./lib.w" as msgfanout;

let fanout = new msgfanout.MessageFanout();

let table = new ex.Table(
  name: "users",
  primaryKey: "msgId",
  columns: {
    "message" => ex.ColumnType.STRING
  }
);

fanout.addConsumer(inflight (msg: str) => {
  table.insert("first", { message: "first {msg}" });
}, name: "first");

fanout.addConsumer(inflight (msg: str) => {
  table.insert("second", { message: "second {msg}" });
}, name: "second");

test "message fanout" {
  fanout.publish("hello 👋");
  
  util.sleep(10s);

  assert(table.get("first")["message"] == "first hello 👋");  
  assert(table.get("second")["message"] == "second hello 👋");
}
