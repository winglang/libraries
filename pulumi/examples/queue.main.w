bring cloud;

let queue = new cloud.Queue();

let b = new cloud.Bucket();

queue.setConsumer(inflight (message) => {
  log("new message: {message}");
  b.put("hello.txt", message);
});

