bring cloud;
bring ex;
bring util;
bring "../websocket.w" as websocket;

let tb = new ex.DynamodbTable(
  name: "WebSocketTable",
  hashKey: "connectionId",
  attributeDefinitions: {
    "connectionId": "S",
  },
);

let wb = new websocket.WebSocket(name: "MyWebSocket") as "my-websocket";

wb.onConnect(inflight(id: str): void => {
  tb.putItem({
    item: {
      "connectionId": id
    }
  });
});

wb.onDisconnect(inflight(id: str): void => {
  tb.deleteItem({
    key: {
      "connectionId": id
    }
  });
});

wb.onMessage(inflight (id: str, body: str): void => {
  let connections = tb.scan();
  for item in connections.items {
    wb.sendMessage(str.fromJson(item.get("connectionId")), body);
  }
});

wb.initialize();

interface IWebSocketJS {
  inflight on(cmd: str, handler: inflight(str):void);
  inflight send(e: str): void;
  inflight close(): void;
}
class Util {
  extern "./util.mts" pub static inflight _ws(url: str): IWebSocketJS;
  extern "./util.mts" pub static inflight _buffer_to_string(data: str): str;
}

let counter = new cloud.Counter(initial: 1);

let receiveMsg = new cloud.Service(inflight () => {
  let ws = Util._ws(wb.url());

  ws.on("open", () => {
    log("open socket (receiver)");
    ws.on("message", (data: str) => {
      let msg = Util._buffer_to_string(data);
      
      let n = num.fromStr(msg);
      assert(n >= 1 && n < 10);
      if msg == "1" {
        log("first message received");
      } elif msg == "9" {
        log("last message received");
        ws.close();
      }
    });
  });

  ws.on("close", () => {
    log("close socket (receiver)");
  });
}, autoStart: false) as "receive message";

let sendMsg = new cloud.Service(inflight () => {
  let ws = Util._ws(wb.url());

  ws.on("open", () => {
    log("open socket (sender)");

    ws.on("message", (data: str) => {
      let msg = Util._buffer_to_string(data);
      
      let n = num.fromStr(msg);
      assert(n >= 1 && n < 10);
      if msg == "1" {
        log("sender also receive the first message");
      } elif msg == "9" {
        log("sender also receive the last message");
        ws.close();
      }
    });

    for i in 1..10 {
      ws.send("{counter.inc()}");
    }
  });

  ws.on("close", () => {
    log("close socket (sender)");
  });
}, autoStart: false) as "send message";

test "simple websocket test" {
  let ws = Util._ws(wb.url());

  receiveMsg.start();
  assert(receiveMsg.started());

  sendMsg.start();
  assert(sendMsg.started());

  util.sleep(10s);

  sendMsg.stop();
  receiveMsg.stop();

  assert(counter.peek() == 10);
}
