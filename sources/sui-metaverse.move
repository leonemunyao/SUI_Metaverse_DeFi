module 0x0::SuiMetaverseLand {

    // Importing necessary modules and functions.
    use std::string::{String};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use std::option::{none, some, borrow};
    // use sui::account::{Self as Account, address};



    public struct SuimetaverseLand has drop {}

    // Struct Definitions. Respresents land parcel with its unique id, area, location, total supply,
    // owners, and optional rental information.
    public struct Land has key, store {
        id: UID,
        area: u64,
        location: String,
        total_supply: u64,
        owners: vector<(address)>,
        rental_info: Option<RentalInfo>,
    }

    // Struct Definitions. Represents rental information with rental price, rental duration, and renter.
    public struct RentalInfo has store, drop {
        rental_price: u64,
        rental_duration: u64,
        renter: Option<address>,
    }


    // Represents an ownership token for a land parcel.
    public struct OwnershipToken has store, key {
        id: UID,
        amount: u64,
    }

    // Fuction to initialize a new land parcel
    public entry fun new_land(
        id: u64,               // Unique ID of the land parcel
        area: u64,              // Area of the land parcel
        location: String,       // Location of the land parcel
        ctx: &mut TxContext     // Transaction context
    ) {
        let land_id = object::new(ctx);  // Create a new unique ID for the land parcel
        let land = Land {
            id: land_id,
            area,
            location,
            total_supply: 0,
            owners: vector::empty<address>(),
            rental_info: none(),
        };
        transfer::share_object(land);
    }

    // Function to reate ownership tokens for the land.
    public fun create_tokens(id: u64, amount: u64, ctx: &mut TxContext): OwnershipToken {
        let token_id = object::new(ctx);
        OwnershipToken { id: token_id, amount }
    }

    // Transfer ownership tokens
    public fun transfer_tokens(
        token: &mut OwnershipToken,
        to: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(token.amount >= amount, 1);
        token.amount = token.amount - amount;
    }

    public fun transfer_ownership_token(token: OwnershipToken, to: address) {
        transfer::public_transfer(token, to);
    }

    // Get balance of ownership tokens
    public fun balance_of(token: &OwnershipToken, owner: address): u64 {
        token.amount
    }


    public fun unlock(ctx: &mut TxContext, land_id: UID, account_addr: address) {
        // Example logic:
        // 1. Verify that the land exists and the caller has the right to unlock coins.
        // 2. Verify that coins are indeed locked for this land parcel.
        // 3. Update the coin balance to reflect the unlocked coins.

        // This is a placeholder for the actual implementation.
        // You would need to interact with the sui::coin and sui::balance modules
        // to manipulate the coin balances, depending on how you've implemented locking.
    }

    // Deposit rent payment
    public fun deposit_rent(
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
    public fun list_land_for_rent(
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
    public fun rent_land(
        land: &mut Land,
        renter: address,
        amount: u64,
        duration: u64,
        ctx: &mut TxContext
    ) {
        assert!(option::is_some(&land.rental_info), 1);
        let rental_info = option::borrow_mut(&mut land.rental_info);
        assert!(option::is_none(&rental_info));
        rental_info.rental_price = amount;
        rental_info.rental_duration = duration;
        rental_info.renter = some(renter);
        coin::lock(ctx, amount);
    }

    // Pay rent
    public fun pay_rent(
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
    public fun withdraw_rent(land: &mut Land, ctx: &mut TxContext) {
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

        let i = 0;
        let owners_len = Vector::length(owners);
        while (i < owners_len) {
            let owner = *Vector::borrow(owners, i);
            let ownership = *Vector::borrow(land.owners, i);
            let owner_rent = total_rent * ownership / land.total_supply;
            coin::mint(ctx, owner_rent);
            transfer::public_transfer(owner_rent, owner);
            i = i + 1;
        }

        land.rental_info = none();
    }
}
