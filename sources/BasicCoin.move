module Coin::BaseCoin {
    use Std::Errors;
    use Std::Signer;
//    use Std::Debug;

    const E_INSUFFICIENT_FUNDS: u64 = 1;
    const E_ALREADY_HAS_BALANCE: u64 = 2;
    const E_SAME_ADDR: u64 = 4;

    struct Coin<phantom CoinType> has store {
        value: u64
    }

    struct Balance<phantom CoinType> has key {
        coin: Coin<CoinType>
    }

    public fun publish_balance<CoinType>(account: &signer) {
        let empty_coin = Coin<CoinType>{ value: 0 };
        assert!(
            !exists<Balance<CoinType>>(Signer::address_of(account)),
            Errors::already_published(E_ALREADY_HAS_BALANCE)
        );
        move_to(account, Balance<CoinType>{ coin: empty_coin });
    }

    spec publish_balance {
        include Schema_publish<CoinType> {addr: Signer::address_of(account), amount: 0};
    }

    spec schema Schema_publish<CoinType> {
        addr: address;
        amount: u64;

        aborts_if exists<Balance<CoinType>>(addr);

        ensures exists<Balance<CoinType>>(addr);

        let post balance_post = global<Balance<CoinType>>(addr);

        ensures balance_post == amount;
    }

    public fun mint<CoinType: drop>(mint_addr: address, amount: u64, _witness: CoinType) acquires Balance {
        deposit(mint_addr, Coin<CoinType> { value: amount })
    }

    spec mint {
        include DepositSchema<CoinType> {addr: mint_addr, amount};
    }

    public fun burn<CoinType: drop>(burn_addr: address, amount: u64, _witness: CoinType) acquires Balance {
        let Coin { value: _ } = withdraw<CoinType>(burn_addr, amount);
    }

    spec burn { }

    public fun balance_of<CoinType>(owner: address): u64 acquires Balance {
        borrow_global<Balance<CoinType>>(owner).coin.value
    }

    spec balance_of {
        pragma aborts_if_is_strict;
        aborts_if !exists<Balance<CoinType>>(owner);
    }

    public fun transfer<CoinType: drop>(from: &signer, to: address, amount: u64, _witness: CoinType) acquires Balance {
        let from_addr = Signer::address_of(from);
        assert!(from_addr != to, E_SAME_ADDR);
        let check = withdraw<CoinType>(from_addr, amount);
        deposit<CoinType>(to, check);
    }

    spec transfer {
        let addr_from = Signer::address_of(from);

        let balance_from = global<Balance<CoinType>>(addr_from).coin.value;
        let balance_to = global<Balance<CoinType>>(to).coin.value;
        let post balance_from_post = global<Balance<CoinType>>(addr_from).coin.value;
        let post balance_to_post = global<Balance<CoinType>>(to).coin.value;

        aborts_if !exists<Balance<CoinType>>(addr_from);
        aborts_if !exists<Balance<CoinType>>(to);
        aborts_if balance_from < amount;
        aborts_if balance_to + amount > MAX_U64;
        aborts_if addr_from == to;

        ensures balance_from_post == balance_from - amount;
        ensures blance_to_post == balance_to + amount;
    }

    fun withdraw<CoinType>(addr: address, amount: u64) : Coin<CoinType> acquires Balance {
        let balance = balance_of<CoinType>(addr);
//        Debug::print(&balance);
//        Debug::print(&amount);
        assert!(balance >= amount, E_INSUFFICIENT_FUNDS);
        let balance_ref = &mut borrow_global_mut<Balance<CoinType>>(addr).coin.value;
        *balance_ref = balance - amount;
        Coin<CoinType> { value: amount }
    }

    spec withdraw {
        let balance = global<Balance<CoinType>>(addr).coin.value;

        aborts_if !exists<Balance<CoinType>>(addr);
        aborts_if balance < amount;

        let post balance_post = global<Balance<CoinType>>(addr).coin.value;
        ensures result == Coin<CoinType> { value: amount };
        ensures balance_post == balance - amount;
    }

    fun deposit<CoinType>(addr: address, check: Coin<CoinType>) acquires Balance {
        let balance = balance_of<CoinType>(addr);
        let balance_ref = &mut borrow_global_mut<Balance<CoinType>>(addr).coin.value;
        let Coin { value } = check;
        *balance_ref = balance + value;
    }

    spec deposit {
        let balance = global<Balance<CoinType>>(addr).coin.value;
        let check_value = check.value;

        aborts_if !exists<Balance<CoinType>>(addr);
        aborts_if balance + check_value > MAX_U64;

        let post balance_post = global<Balance<CoinType>>(addr).coin.value;
        ensures balance_post == balance + check_value;
    }

    spec schema DepositSchema<CoinType> {
        addr: address;
        amount: u64;
        let balance = global<Balance<CoinType>>(addr).coin.value;

        aborts_if !exists<Balance<CoinType>>(addr);
        aborts_if balance + amount > MAX_U64;

        let post balance_post = global<Balance<CoinType>>(addr).coin.value;
        ensures balance_post == balance_post + amount;

    }
}
