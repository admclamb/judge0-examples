import Mocha from "mocha";
import { expect } from "chai";

const mocha = new Mocha();

// Inject Mocha’s globals into the current scope.
// This is what normally the mocha CLI does for you.
mocha.suite.emit("pre-require", global, "", mocha);

function add(a, b) {
  return a + b;
}

describe("Calculator Module", () => {
  describe("add()", () => {
    it("should correctly add two numbers", () => {
      const result = add(2, 3);
      expect(result).to.equal(5);
    });

    it("should return a number", () => {
      const result = add(1, 2);
      expect(result).to.be.a("number");
    });
  });
});

// Run the tests and exit the process with an appropriate code.
mocha.run((failures) => {
  process.exitCode = failures ? 1 : 0;
});
