import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can create community",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("community-manager", "create-community", 
        [types.utf8("Test Community")], 
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), "u1");
  },
});

Clarinet.test({
  name: "Ensure can join community",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("community-manager", "create-community", 
        [types.utf8("Test Community")], 
        wallet_1.address
      ),
      Tx.contractCall("community-manager", "join-community",
        [types.uint(1)],
        wallet_2.address
      )
    ]);
    
    assertEquals(block.receipts[1].result.expectOk(), true);
  },
});

Clarinet.test({
  name: "Ensure cannot join community twice",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("community-manager", "create-community", 
        [types.utf8("Test Community")], 
        wallet_1.address
      ),
      Tx.contractCall("community-manager", "join-community",
        [types.uint(1)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[1].result.expectErr(), "u103");
  },
});
