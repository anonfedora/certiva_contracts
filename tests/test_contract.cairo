#[cfg(test)]
mod tests {
    use core::byte_array::ByteArrayTrait;
    use core::result::ResultTrait;
    use core::traits::TryInto;
    use snforge_std::{
        ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
        start_cheat_caller_address, stop_cheat_caller_address,
    };
    use starknet::{ContractAddress, contract_address_const};
    use unichain_contracts::Interfaces::ICertiva::{ICertivaDispatcher, ICertivaDispatcherTrait};
    use unichain_contracts::certiva::Certiva;
    use unichain_contracts::certiva::Certiva::University;

    fn setup() -> (ContractAddress, ICertivaDispatcher) {
        let contract = declare("Certiva").unwrap().contract_class();
        let owner = contract_address_const::<'owner'>();

        let (contract_address, _) = contract.deploy(@array![owner.into()]).unwrap();
        let dispatcher = ICertivaDispatcher { contract_address: contract_address };

        (owner, dispatcher)
    }

    #[test]
    fn test_register_university() {
        let (owner, dispatcher) = setup();

        // Test data
        let university_name = 'Harvard University';
        let website_domain = "nnamdi azikiwe university";
        let country = 'USA';
        let accreditation_body = 'NECHE';
        let university_email = "nnamdiazikiweuniversity@gmail.com";
        let wallet_address = contract_address_const::<2>();

        // Register university as owner
        start_cheat_caller_address(dispatcher.contract_address, owner);
        dispatcher
            .register_university(
                university_name,
                website_domain,
                country,
                accreditation_body,
                university_email,
                wallet_address,
            );
        stop_cheat_caller_address(dispatcher.contract_address);

        // Verify university was registered correctly
        let stored_university = dispatcher.get_university(wallet_address);
        assert(stored_university.university_name == university_name, 'Wrong university name');
        assert(stored_university.country == country, 'Wrong country');
        assert(stored_university.wallet_address == wallet_address, 'Wrong wallet address');
    }

    #[test]
    #[should_panic(expected: 'Unauthorized caller')]
    fn test_register_university_unauthorized() {
        let (owner, dispatcher) = setup();

        // Test data
        let university_name = 'Harvard University';
        let website_domain = "nnamdi azikiwe university";
        let country = 'USA';
        let accreditation_body = 'NECHE';
        let university_email = "nnamdiazikiweuniversity@gmail.com";
        let wallet_address = contract_address_const::<2>();

        let non_owner = contract_address_const::<'non_owner'>();

        // Try to register university as non-owner
        // Register university as owner
        start_cheat_caller_address(dispatcher.contract_address, non_owner);
        dispatcher
            .register_university(
                university_name,
                website_domain,
                country,
                accreditation_body,
                university_email,
                wallet_address,
            );
        stop_cheat_caller_address(dispatcher.contract_address);
    }

    #[test]
    fn test_register_university_optional_field() {
        // Deploy the contract
        let (owner, dispatcher) = setup();

        // Test data
        let university_name = 'Harvard University';
        let website_domain = "nnamdi azikiwe university";
        let country = 'USA';
        let accreditation_body = '';
        let university_email = "nnamdiazikiweuniversity@gmail.com";
        let wallet_address = contract_address_const::<2>();

        let non_owner = contract_address_const::<'non_owner'>();

        // Try to register university as non-owner
        // Register university as owner
        start_cheat_caller_address(dispatcher.contract_address, owner);
        dispatcher
            .register_university(
                university_name,
                website_domain,
                country,
                accreditation_body,
                university_email,
                wallet_address,
            );
        stop_cheat_caller_address(dispatcher.contract_address);
    }

    #[test]
    fn test_register_university_event() {
        // Deploy the contract
        let (owner, dispatcher) = setup();
        
        // Test data
        let university_name = 'Harvard University';
        let website_domain_str: ByteArray = "nnamdi azikiwe university";
        let country = 'USA';
        let accreditation_body = 'dsscscnbs';
        let university_email_str: ByteArray = "nnamdiazikiweuniversity@gmail.com";
        let wallet_address = contract_address_const::<2>();
        
        let mut spy = spy_events();
        
        // Register university as owner
        start_cheat_caller_address(dispatcher.contract_address, owner);
        dispatcher.register_university(
            university_name,
            website_domain_str.clone(),
            country,
            accreditation_body,
            university_email_str.clone(),
            wallet_address,
        );
        stop_cheat_caller_address(dispatcher.contract_address);
        
        // Use the same values in the event assertion as were used in the function call
        spy.assert_emitted(
            @array![
                (
                    dispatcher.contract_address,
                    Certiva::Event::university_created(
                        University {
                            university_name,
                            website_domain: website_domain_str, // Use the original value
                            country,
                            accreditation_body,
                            university_email: university_email_str, // Use the original value
                            wallet_address,
                        },
                    ),
                ),
            ],
        );
    }
}
