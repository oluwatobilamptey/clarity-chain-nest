import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can create and edit post",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("content-manager", "create-post",
        [types.uint(1), types.utf8("Initial content")],
        wallet_1.address
      ),
      Tx.contractCall("content-manager", "edit-post",
        [types.uint(1), types.utf8("Updated content")],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), "u1");
    assertEquals(block.receipts[1].result.expectOk(), true);
  },
});

Clarinet.test({
  name: "Ensure cannot create post with empty content",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("content-manager", "create-post",
        [types.uint(1), types.utf8("")],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectErr(), "u204");
  },
});
