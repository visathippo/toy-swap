module SilverCoin::SilverCoin {
    use Std::Signer;
    use Coin::BaseCoin;

    struct SilverCoin has drop {}

    public fun setup_and_mint(account: &signer, amount: u64) {
        BaseCoin::publish_balance<SilverCoin>(account);
        BaseCoin::mint<SilverCoin>(Signer::address_of(account), amount, SilverCoin {});
    }

    public fun transfer(from: &signer, to: address, amount: u64) {
        BaseCoin::transfer<SilverCoin>(from, to, amount, SilverCoin {});
    }

    public fun empty() :SilverCoin {
        SilverCoin {}
    }
}
