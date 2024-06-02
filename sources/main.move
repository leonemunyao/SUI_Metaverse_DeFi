module SuiMetaverseLand {
    use 0x1::Coin;
    use 0x1::Account;
    use 0x1::Transfer;
    use 0x1::Vector;
    use 0x1::String;
    use 0x1::Map;

    // Step 1: Land Parcel Representation
    struct Land {
        id: u64,
        area: u64,
        location: String,
        total_supply: u64,
        owners: Map<Address, u64>, // Address to ownership percentage
        rental_info: Option<RentalInfo>,
    }

    struct RentalInfo {
        rental_price: u64,
        rental_duration: u64,
        renter: Option<Address>,
    }

    // Step 2: Fractional Ownership Management
    resource struct OwnershipToken {
        id: u64,
        amount: u64,
    }

    // Initialize a new land parcel
    public fun new_land(id: u64, area: u64, location: String, ctx: &mut TxContext): Land {
        Land {
            id,
            area,
            location,
            total_supply: 0,
            owners: Map::new(),
            rental_info: Option::none(),
        }
    }

    // Create ownership tokens
    public fun create_tokens(id: u64, amount: u64, ctx: &mut TxContext): OwnershipToken {
        OwnershipToken { id, amount }
    }

    // Transfer ownership tokens
    public fun transfer_tokens(
        token: &mut OwnershipToken,
        to: Address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(token.amount >= amount, 1);
        token.amount -= amount;
        Transfer::public_transfer(token, to);
    }

    // Get balance of ownership tokens
    public fun balance_of(token: &OwnershipToken, owner: Address): u64 {
        token.amount
    }

    // Step 3: Rental Agreements
    // Deposit rent payment
    public fun deposit_rent(
        land: &mut Land,
        amount: u64,
        renter: Address,
        duration: u64,
        ctx: &mut TxContext
    ) {
        assert!(land.rental_info.is_none(), 1); // Ensure no active rental
        let rental_info = RentalInfo {
            rental_price: amount,
            rental_duration: duration,
            renter: Option::some(renter),
        };
        land.rental_info = Option::some(rental_info);
        Coin::lock(ctx, amount);
    }

    // Step 4: Rental Listings & Bookings
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
            renter: Option::none(),
        };
        land.rental_info = Option::some(rental_info);
    }

    // Rent land parcel
    public fun rent_land(
        land: &mut Land,
        renter: Address,
        amount: u64,
        duration: u64,
        ctx: &mut TxContext
    ) {
        assert!(land.rental_info.borrow().is_some(), 1); // Ensure land is listed
        let rental_info = land.rental_info.borrow_mut();
        rental_info.rental_price = amount;
        rental_info.rental_duration = duration;
        rental_info.renter = Option::some(renter);
        Coin::lock(ctx, amount);
    }

    // Step 5: Rent Payments
    // Pay rent
    public fun pay_rent(
        land: &mut Land,
        renter: Address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(land.rental_info.borrow().is_some(), 1); // Ensure there is an active rental
        let rental_info = land.rental_info.borrow();
        assert!(rental_info.renter == Option::some(renter), 1); // Ensure the correct renter
        Coin::lock(ctx, amount);
        distribute_rent(land, ctx);
    }

    // Withdraw rent payment
    public fun withdraw_rent(land: &mut Land, ctx: &mut TxContext) {
        let rental_info = land.rental_info.borrow();
        assert!(rental_info.is_some(), 1); // Ensure there is an active rental
        let rental_info = rental_info.borrow();
        let amount = rental_info.rental_price;
        Coin::unlock(ctx, amount);
        land.rental_info = Option::none();
    }

    // Distribute rent to landowners
    public fun distribute_rent(land: &Land, ctx: &mut TxContext) {
        let owners = land.owners;
        let rental_info = land.rental_info.borrow();
        assert!(rental_info.is_some(), 1); // Ensure there is an active rental
        let rental_info = rental_info.borrow();
        let total_rent = rental_info.rental_price;
        for (owner, ownership) in owners {
            let owner_rent = total_rent * ownership / land.total_supply;
            Coin::mint(ctx, owner_rent);
            Transfer::public_transfer(owner_rent, owner);
        }
        land.rental_info = Option::none();
    }
}
