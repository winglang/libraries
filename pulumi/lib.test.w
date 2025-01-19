bring expect;
bring "./lib.w" as l;

let adder = new l.Adder();

test "add() adds two numbers" {
  expect.equal(adder.add(1, 2), 3);
}
