import { expect } from "chai";

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
