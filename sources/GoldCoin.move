module GoldCoin::GoldCoin {
    use Std::Signer;
    use Coin::BaseCoin;

    struct GoldCoin has drop {}

    public fun setup_and_mint(account: &signer, amount: u64) {
        BaseCoin::publish_balance<GoldCoin>(account);
        BaseCoin::mint<GoldCoin>(Signer::address_of(account), amount, GoldCoin{});
    }

    public fun transfer(from: &signer, to: address, amount: u64) {
        BaseCoin::transfer<GoldCoin>(from, to, amount, GoldCoin {});
    }

    public fun empty() :GoldCoin {
        GoldCoin {}
    }
}
