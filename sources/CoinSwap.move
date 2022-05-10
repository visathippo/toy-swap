module CoinSwap::CoinSwap {
    use Std::Signer;
    use Std::Errors;
    use Coin::BaseCoin;
    use CoinSwap::PoolToken;

    const E_COINSWAP_ADDRESS: u64 = 0;
    const E_POOL: u64 = 1;

    struct LiquidityPool<phantom CoinType1, phantom CoinType2> has key {
        coin1: u64,
        coin2: u64,
        share: u64,
    }

    public fun create_pool<CoinType1: drop, CoinType2: drop>(
        coinswap: &signer,
        requester: &signer,
        coin1: u64,
        coin2: u64,
        share: u64,
        witness1: CoinType1,
        witness2: CoinType2
    ) {
        BaseCoin::publish_balance<CoinType1>(coinswap);
        BaseCoin::publish_balance<CoinType2>(coinswap);
        assert!(Signer::address_of(coinswap) == @CoinSwap, Errors::invalid_argument(E_COINSWAP_ADDRESS));
        assert!(!exists<LiquidityPool<CoinType1, CoinType2>>(Signer::address_of(coinswap)), Errors::already_published(E_POOL));
        move_to(coinswap, LiquidityPool<CoinType1, CoinType2>{coin1, coin2, share});

        BaseCoin::transfer<CoinType1>(requester, Signer::address_of(coinswap), coin1, witness1);
        BaseCoin::transfer<CoinType2>(requester, Signer::address_of(coinswap), coin2, witness2);

        PoolToken::setup_and_mint<CoinType2, CoinType2>(requester, share);
    }

    fun get_input_price(input_amount: u64, input_reserve: u64, output_reserve: u64): u64 {
        let input_amount_with_fee = input_amount * 997;
        let numerator = input_amount_with_fee * output_reserve;
        let denominator = (input_reserve * 1000) + input_amount_with_fee;
        numerator / denominator
    }

    public fun coin1_to_coin2_swap_input<CoinType1: drop, CoinType2: drop>(
        coinswap: &signer,
        requester: &signer,
        coin1: u64,
        witness1: CoinType1,
        witness2: CoinType2
    ) acquires LiquidityPool {
        assert!(Signer::address_of(coinswap) == @CoinSwap, Errors::invalid_argument(E_COINSWAP_ADDRESS));
        assert!(exists<LiquidityPool<CoinType1, CoinType2>>(Signer::address_of(coinswap)), Errors::not_published(E_POOL));
        let pool = borrow_global_mut<LiquidityPool<CoinType1, CoinType2>>(Signer::address_of(coinswap));
        let coin2 = get_input_price(coin1, pool.coin1, pool.coin2);

        pool.coin1 = pool.coin1 + coin1;
        pool.coin2 = pool.coin2 - coin2;

        BaseCoin::transfer<CoinType1>(requester, Signer::address_of(coinswap), coin1, witness1);
        BaseCoin::transfer<CoinType2>(coinswap, Signer::address_of(requester), coin2, witness2);
    }

    public fun add_liquidity<CoinType1: drop, CoinType2: drop> (
        account: &signer,
        coin1: u64,
        coin2: u64,
        witness1: CoinType1,
        witness2: CoinType2,
    ) acquires LiquidityPool {
        let pool = borrow_global_mut<LiquidityPool<CoinType1, CoinType2>>(@CoinSwap);

        let coin1_added = coin1;
        let share_minted = (coin1_added * pool.share) / pool.coin1;
        let coin2_added = (share_minted * pool.coin2) / pool.share;

        pool.coin1 = pool.coin1 + coin1_added;
        pool.coin2 = pool.coin2 + coin2_added;
        pool.share = pool.share + share_minted;

        BaseCoin::transfer<CoinType1>(account, @CoinSwap, coin1, witness1);
        BaseCoin::transfer<CoinType2>(account, @CoinSwap, coin2, witness2);
        PoolToken::mint<CoinType1, CoinType2>(Signer::address_of(account), share_minted);
    }

    public fun remove_liquidity<CoinType1: drop, CoinType2: drop> (
        coinswap: &signer,
        requester: &signer,
        share: u64,
        witness1: CoinType1,
        witness2: CoinType2,
    ) acquires LiquidityPool {
        let pool = borrow_global_mut<LiquidityPool<CoinType1, CoinType2>>(@CoinSwap);

        let coin1_removed = (pool.coin1 * share) / pool.share;
        let coin2_removed = (pool.coin2 * share) / pool.share;

        pool.coin1 = pool.coin1 - coin1_removed;
        pool.coin2 = pool.coin2 - coin2_removed;
        pool.share = pool.share - share;

        BaseCoin::transfer<CoinType1>(coinswap, Signer::address_of(requester), coin1_removed, witness1);
        BaseCoin::transfer<CoinType2>(coinswap, Signer::address_of(requester), coin2_removed, witness2);
        PoolToken::burn<CoinType1, CoinType2>(Signer::address_of(requester), share)
    }


    #[test_only]
    public fun get_state<CoinType1, CoinType2>(): vector<u64> acquires LiquidityPool {
        use Std::Vector;
        let result = Vector::empty<u64>();
        let pool = borrow_global_mut<LiquidityPool<CoinType1, CoinType2>>(@CoinSwap);
        Vector::push_back(&mut result, pool.coin1);
        Vector::push_back(&mut result, pool.coin2);
        Vector::push_back(&mut result, pool.share);
        result
    }
}
