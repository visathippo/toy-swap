module CoinSwap::Tests {


    #[test(coinswap=@CoinSwap, a=@0xC)]
    public fun test_all (coinswap: &signer, a: &signer) {
        use Std::Debug;
        use Std::Signer;
        use CoinSwap::CoinSwap;
        use GoldCoin::GoldCoin;
        use SilverCoin::SilverCoin;
        use Coin::BaseCoin;
        GoldCoin::setup_and_mint(a, 50);
        SilverCoin::setup_and_mint(a, 30);
        let c1 = BaseCoin::balance_of<GoldCoin::GoldCoin>(Signer::address_of(a));
        let c2 = BaseCoin::balance_of<SilverCoin::SilverCoin>(Signer::address_of(a));
        CoinSwap::create_pool<GoldCoin::GoldCoin, SilverCoin::SilverCoin>(
            coinswap, a, c1, c2, 100, GoldCoin::empty(), SilverCoin::empty()
        );
        let v = CoinSwap::get_state<GoldCoin::GoldCoin, SilverCoin::SilverCoin>();
        Debug::print(&v);
    }
}
