import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test event creation - owner only",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const owner = accounts.get('deployer')!;
    const user = accounts.get('wallet_1')!;

    // Test successful event creation by owner
    let block = chain.mineBlock([
      Tx.contractCall('tag-trek', 'create-event', [
        types.ascii("Test Event"),
        types.uint(1000),
        types.uint(2000)
      ], owner.address)
    ]);
    assertEquals(block.receipts[0].result.expectOk(), '1');

    // Test failed event creation by non-owner
    block = chain.mineBlock([
      Tx.contractCall('tag-trek', 'create-event', [
        types.ascii("Test Event"),
        types.uint(1000),
        types.uint(2000)
      ], user.address)
    ]);
    block.receipts[0].result.expectErr().expectUint(100);
  },
});

Clarinet.test({
  name: "Test tag placement and claiming",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const owner = accounts.get('deployer')!;
    const user = accounts.get('wallet_1')!;

    // Create event and place tag
    let block = chain.mineBlock([
      Tx.contractCall('tag-trek', 'create-event', [
        types.ascii("Test Event"),
        types.uint(1000),
        types.uint(2000)
      ], owner.address),
      Tx.contractCall('tag-trek', 'place-tag', [
        types.uint(1),
        types.uint(1),
        types.int(40000000),
        types.int(-73000000),
        types.uint(100),
        types.ascii("Test Tag")
      ], owner.address)
    ]);

    // Test tag claiming
    block = chain.mineBlock([
      Tx.contractCall('tag-trek', 'claim-tag', [
        types.uint(1),
        types.uint(1)
      ], user.address)
    ]);
    assertEquals(block.receipts[0].result.expectOk(), true);

    // Verify score update
    let scoreResult = chain.callReadOnlyFn(
      'tag-trek',
      'get-score',
      [types.uint(1), types.principal(user.address)],
      user.address
    );
    assertEquals(scoreResult.result.expectOk().score, 100);
  },
});
