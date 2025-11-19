import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const deployer = accounts.get("deployer")!;

const contractName = "Peer-Review-Verification-System";

describe("Peer Review Verification System Tests", () => {
  it("ensures simnet is well initialized", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  describe("Research Impact Scoring System", () => {
    it("should register scientist and submit research", () => {
      // Register scientist
      const registerResult = simnet.callPublicFn(
        contractName,
        "register-scientist",
        [Cl.stringAscii("Dr. Alice Smith"), Cl.stringAscii("MIT")],
        address1
      );
      expect(registerResult.result).toBeOk();

      // Submit research
      const submitResult = simnet.callPublicFn(
        contractName,
        "submit-research",
        [
          Cl.stringAscii("Quantum Computing Breakthrough"),
          Cl.stringAscii("Revolutionary approach to quantum error correction"),
          Cl.stringAscii("QmYwAPJzv5CZsnA625s3Xf2femX5McnLuVxEJO56Ct7vEQ")
        ],
        address1
      );
      expect(submitResult.result).toBeOk();
    });

    it("should calculate and retrieve impact scores", () => {
      // Get research ID from previous test setup
      const researchId = Cl.uint(1);

      // Calculate impact score
      const impactResult = simnet.callPublicFn(
        contractName,
        "calculate-impact-score",
        [researchId],
        address1
      );
      expect(impactResult.result).toBeOk();

      // Retrieve impact score
      const scoreResult = simnet.callReadOnlyFn(
        contractName,
        "get-research-impact-score",
        [researchId],
        address1
      );
      expect(scoreResult.result).toBeSome();
    });

    it("should handle error cases correctly", () => {
      // Try to calculate impact for non-existent research
      const invalidResult = simnet.callPublicFn(
        contractName,
        "calculate-impact-score",
        [Cl.uint(999)],
        address1
      );
      expect(invalidResult.result).toBeErr();
    });

    it("should update impact weights (owner only)", () => {
      // Try updating weights as non-owner (should fail)
      const nonOwnerResult = simnet.callPublicFn(
        contractName,
        "set-impact-weights",
        [Cl.uint(50), Cl.uint(30), Cl.uint(20)],
        address1
      );
      expect(nonOwnerResult.result).toBeErr();

      // Update weights as owner (should succeed)
      const ownerResult = simnet.callPublicFn(
        contractName,
        "set-impact-weights",
        [Cl.uint(50), Cl.uint(30), Cl.uint(20)],
        deployer
      );
      expect(ownerResult.result).toBeOk();
    });
  });
});


