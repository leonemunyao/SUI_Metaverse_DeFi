module 0x0::SuiMetaverseLand {
    use std::string::{String};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use std::option::{none, some, borrow};
    use sui::account::{Self as Account, address};

    // Structs
    public struct Land has key, store {
        id: UID,
        area: u64,
        location: String,
        total_supply: u64,
        owners: vector<(address)>,
        rental_info: Option<RentalInfo>,
    }

    public struct RentalInfo has store {
        rental_price: u64,
        rental_duration: u64,
        renter: Option<address>,
    }

    public struct OwnershipToken has store {
        id: UID,
        amount: u64,
    }

    // Initialize a new land parcel
    public entry fun new_land(
        id: u64,
        area: u64,
        location: String,
        ctx: &mut TxContext
    ) {
        let land_id = object::new(ctx);
        let land = Land {
            id: land_id,
            area,
            location,
            total_supply: 0,
            owners: vector::empty<(address, u64)>(),
            rental_info: none(),
        };
        transfer::share_object(land);
    }

    // Create ownership tokens
    public entry fun create_tokens(id: u64, amount: u64, ctx: &mut TxContext): OwnershipToken {
        let token_id = object::new(ctx);
        OwnershipToken { id: token_id, amount }
    }

    // Transfer ownership tokens
    public entry fun transfer_tokens(
        token: &mut OwnershipToken,
        to: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(token.amount >= amount, 1);
        token.amount = token.amount - amount;
        transfer::public_transfer(token, to);
    }

    // Get balance of ownership tokens
    public fun balance_of(token: &OwnershipToken, owner: address): u64 {
        token.amount
    }

    // Deposit rent payment
    public entry fun deposit_rent(
        land: &mut Land,
        amount: u64,
        renter: address,
        duration: u64,
        ctx: &mut TxContext
    ) {
        assert!(option::is_none(&land.rental_info), 1);
        let rental_info = RentalInfo {
            rental_price: amount,
            rental_duration: duration,
            renter: some(renter),
        };
        land.rental_info = some(rental_info);
        coin::lock(ctx, amount);
    }

    // List land for rent
    public entry fun list_land_for_rent(
        land: &mut Land,
        rental_price: u64,
        rental_duration: u64,
        ctx: &mut TxContext
    ) {
        let rental_info = RentalInfo {
            rental_price,
            rental_duration,
            renter: none(),
        };
        land.rental_info = some(rental_info);
    }

    // Rent land parcel
    public entry fun rent_land(
        land: &mut Land,
        renter: address,
        amount: u64,
        duration: u64,
        ctx: &mut TxContext
    ) {
        assert!(option::is_some(&land.rental_info), 1);
        let rental_info = option::borrow_mut(&mut land.rental_info).unwrap();
        rental_info.rental_price = amount;
        rental_info.rental_duration = duration;
        rental_info.renter = some(renter);
        coin::lock(ctx, amount);
    }

    // Pay rent
    public entry fun pay_rent(
        land: &mut Land,
        renter: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(option::is_some(&land.rental_info), 1);
        let rental_info = option::borrow(&land.rental_info).unwrap();
        assert!(rental_info.renter == some(renter), 1);
        coin::lock(ctx, amount);
        distribute_rent(land, ctx);
    }

    // Withdraw rent payment
    public entry fun withdraw_rent(land: &mut Land, ctx: &mut TxContext) {
        let rental_info = option::borrow(&land.rental_info).unwrap();
        assert!(option::is_some(rental_info), 1);
        let amount = rental_info.rental_price;
        coin::unlock(ctx, amount);
        land.rental_info = none();
    }

    // Distribute rent to landowners
    public fun distribute_rent(land: &Land, ctx: &mut TxContext) {
        let owners = &land.owners;
        let rental_info = option::borrow(&land.rental_info).unwrap();
        assert!(option::is_some(rental_info), 1);
        let total_rent = rental_info.rental_price;
        for (owner, ownership) in vector::iter(owners) {
            let owner_rent = total_rent * ownership / land.total_supply;
            coin::mint(ctx, owner_rent);
            transfer::public_transfer(owner_rent, *owner);
        }
        land.rental_info = none();
    }
}
