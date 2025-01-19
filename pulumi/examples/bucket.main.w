bring cloud;

let b = new cloud.Bucket(public: true, cors: true);

b.addObject("first.txt", "Uploaded during deployment");

new cloud.Function(inflight () => {
  b.put("hello.txt", "Hello, World!");
});

