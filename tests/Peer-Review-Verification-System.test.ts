import { Clarinet, Tx, Chain, Account, types } from '@stacks/transactions';

Clarinet.test({
  name: "Ensures scientists can register and submit research",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const scientist = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "peer-review-verification-system",
        "register-scientist",
        [types.ascii("John Doe"), types.ascii("MIT")],
        scientist.address
      ),
      Tx.contractCall(
        "peer-review-verification-system",
        "submit-research",
        [
          types.ascii("Research Title"),
          types.ascii("Abstract"),
          types.ascii("QmHash")
        ],
        scientist.address
      )
    ]);

    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectOk().expectUint(1);
  }
});

Clarinet.test({
  name: "Ensures reviewers can submit reviews",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const reviewer = accounts.get("wallet_2")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "peer-review-verification-system",
        "register-reviewer",
        [types.ascii("Jane Smith"), types.ascii("Biology")],
        reviewer.address
      ),
      Tx.contractCall(
        "peer-review-verification-system",
        "submit-review",
        [types.uint(1), types.uint(85), types.ascii("Good research")],
        reviewer.address
      )
    ]);

    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectOk();
  }
});
