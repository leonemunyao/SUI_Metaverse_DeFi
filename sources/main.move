/*
Disclaimer: Use of Unaudited Code for Educational Purposes Only
This code is provided strictly for educational purposes and has not undergone any formal security audit. 
It may contain errors, vulnerabilities, or other issues that could pose risks to the integrity of your system or data.

By using this code, you acknowledge and agree that:
    - No Warranty: The code is provided "as is" without any warranty of any kind, either express or implied. The entire risk as to the quality and performance of the code is with you.
    - Educational Use Only: This code is intended solely for educational and learning purposes. It is not intended for use in any mission-critical or production systems.
    - No Liability: In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the use or performance of this code.
    - Security Risks: The code may not have been tested for security vulnerabilities. It is your responsibility to conduct a thorough security review before using this code in any sensitive or production environment.
    - No Support: The authors of this code may not provide any support, assistance, or updates. You are using the code at your own risk and discretion.

Before using this code, it is recommended to consult with a qualified professional and perform a comprehensive security assessment. By proceeding to use this code, you agree to assume all associated risks and responsibilities.
*/

#[lint_allow(self_transfer)]
module dacade_deepbook::book {
    use deepbook::clob_v2 as deepbook;
    use deepbook::custodian_v2 as custodian;
    use sui::sui::SUI;
    use sui::tx_context::{TxContext, Self};
    use sui::coin::{Coin, Self};
    use sui::balance::{Self};
    use sui::transfer::Self;
    use sui::clock::Clock;

    const FLOAT_SCALING: u64 = 1_000_000_000;


    public fun new_pool<Base, Quote>(payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        let balance = coin::balance_mut(payment);
        let fee = balance::split(balance, 100 * 1_000_000_000);
        let coin = coin::from_balance(fee, ctx);

        deepbook::create_pool<Base, Quote>(
            1 * FLOAT_SCALING,
            1,
            coin,
            ctx
        );
    }

 