module CoinSwap::PoolToken {
    use Std::Signer;
    use Coin::BaseCoin;

    struct PoolToken<phantom CoinType1, phantom CoinType2> has drop {}

    public fun setup_and_mint<CoinType1, CoinType2>(account: &signer, amount: u64) {
        BaseCoin::publish_balance<PoolToken<CoinType1, CoinType2>>(account);
        BaseCoin::mint<PoolToken<CoinType1, CoinType2>>(Signer::address_of(account), amount, PoolToken {});
    }

    public fun transfer<CoinType1, CoinType2>(from: &signer, to: address, amount: u64) {
        BaseCoin::transfer<PoolToken<CoinType1, CoinType2>>(from, to, amount, PoolToken<CoinType1, CoinType2> {});
    }

    public fun mint<CoinType1, CoinType2>(mint_addr: address, amount: u64) {
        BaseCoin::mint(mint_addr, amount, PoolToken<CoinType1, CoinType2> {});
    }

    public fun burn<CoinType1, CoinType2>(burn_addr: address, amount: u64) {
        BaseCoin::burn(burn_addr, amount, PoolToken<CoinType1, CoinType2> {});
    }
}
