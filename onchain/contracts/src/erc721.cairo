use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC721<TContractState> {
    fn get_name(self: @TContractState) -> felt252;
    fn get_symbol(self: @TContractState) -> felt252;
    fn get_token_uri(self: @TContractState, token_id: u256) -> felt252;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn get_total_nft(self: @TContractState) -> u256;
    fn get_token_ids_of_address(self: @TContractState, address: ContractAddress) -> Array<u256>;
    fn is_approved_for_all(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn approve(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
    fn mint(ref self: TContractState, to: ContractAddress);
}

#[starknet::contract]
mod ERC721 {
    ////////////////////////////////
    // library imports
    ////////////////////////////////
    use core::array::ArrayTrait;
    use starknet::{ContractAddress, get_caller_address};
    use core::traits::TryInto;
    use core::num::traits::zero::Zero;

    ////////////////////////////////
    // storage variables
    ////////////////////////////////
    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        owners: LegacyMap::<u256, ContractAddress>,
        balances: LegacyMap::<ContractAddress, u256>,
        token_approvals: LegacyMap::<u256, ContractAddress>,
        operator_approvals: LegacyMap::<(ContractAddress, ContractAddress), bool>,
        token_uri: LegacyMap<u256, felt252>,
        counter: u256,
        // Track the token ids belonging to an address
        // address -> (u256, u256); where address is the user address, first u256 is the index, second u256 is the value (token id)
        token_ids_of_address: LegacyMap<(ContractAddress, u256), u256>,
        token_count_of_address: LegacyMap<ContractAddress, u256>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Approval: Approval,
        Transfer: Transfer,
        ApprovalForAll: ApprovalForAll
    }

    ////////////////////////////////
    // Approval event emitted on token approval
    ////////////////////////////////
    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    ////////////////////////////////
    // Transfer event emitted on token transfer
    ////////////////////////////////
    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    ////////////////////////////////
    // ApprovalForAll event emitted on approval for operators
    ////////////////////////////////
    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    }


    ////////////////////////////////
    // Constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(ref self: ContractState, _name: felt252, _symbol: felt252) {
        self.name.write(_name);
        self.symbol.write(_symbol);
    }

    #[abi(embed_v0)]
    impl IERC721Impl of super::IERC721<ContractState> {
        ////////////////////////////////
        // get_name function returns token name
        ////////////////////////////////
        fn get_name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        ////////////////////////////////
        // get_symbol function returns token symbol
        ////////////////////////////////
        fn get_symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        ////////////////////////////////
        // token_uri returns the token uri
        ////////////////////////////////
        fn get_token_uri(self: @ContractState, token_id: u256) -> felt252 {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self.token_uri.read(token_id)
        }

        ////////////////////////////////
        // balance_of function returns token balance
        ////////////////////////////////
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            assert(account.is_non_zero(), 'ERC721: address zero');
            self.balances.read(account)
        }

        ////////////////////////////////
        // owner_of function returns owner of token_id
        ////////////////////////////////
        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = self.owners.read(token_id);
            owner
        }

        ////////////////////////////////
        // get_approved function returns approved address for a token
        ////////////////////////////////
        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self.token_approvals.read(token_id)
        }

        ////////////////////////////////
        // get total count of NFT minted
        ////////////////////////////////
        fn get_total_nft(self: @ContractState) -> u256 {
            self.counter.read()
        }

        ////////////////////////////////
        // get NFT Ids owned by an address
        ////////////////////////////////
        fn get_token_ids_of_address(self: @ContractState, address: ContractAddress) -> Array<u256> {
            let mut token_ids: Array<u256> = ArrayTrait::new();
            let number_of_ids = self.token_count_of_address.read(address);

            let mut i: u256 = 0;
            while i < number_of_ids {
                let token_id = self.token_ids_of_address.read((address, i));
                token_ids.append(token_id);
                i += 1;
            };

            token_ids
        }

        ////////////////////////////////
        // is_approved_for_all function returns approved operator for a token
        ////////////////////////////////
        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.operator_approvals.read((owner, operator))
        }

        ////////////////////////////////
        // approve function approves an address to spend a token
        ////////////////////////////////
        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self.owner_of(token_id);
            assert(to != owner, 'Approval to current owner');
            assert(
                get_caller_address() == owner
                    || self.is_approved_for_all(owner, get_caller_address()),
                'Not token owner'
            );
            self.token_approvals.write(token_id, to);
            self.emit(Approval { owner: self.owner_of(token_id), to: to, token_id: token_id });
        }

        ////////////////////////////////
        // set_approval_for_all function approves an operator to spend all tokens 
        ////////////////////////////////
        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            let owner = get_caller_address();
            assert(owner != operator, 'ERC721: approve to caller');
            self.operator_approvals.write((owner, operator), approved);
            self.emit(ApprovalForAll { owner: owner, operator: operator, approved: approved });
        }

        ////////////////////////////////
        // transfer_from function is used to transfer a token
        ////////////////////////////////
        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(
                self._is_approved_or_owner(get_caller_address(), token_id),
                'neither owner nor approved'
            );
            self._transfer(from, to, token_id);
        }

        fn mint(ref self: ContractState, to: ContractAddress) {
            self._mint(to);
        }
    }

    #[generate_trait]
    impl ERC721HelperImpl of ERC721HelperTrait {
        ////////////////////////////////
        // internal function to check if a token exists
        ////////////////////////////////
        fn _exists(self: @ContractState, token_id: u256) -> bool {
            // check that owner of token is not zero
            self.owner_of(token_id).is_non_zero()
        }

        ////////////////////////////////
        // _is_approved_or_owner checks if an address is an approved spender or owner
        ////////////////////////////////
        fn _is_approved_or_owner(
            self: @ContractState, spender: ContractAddress, token_id: u256
        ) -> bool {
            let owner = self.owners.read(token_id);
            spender == owner
                || self.is_approved_for_all(owner, spender)
                || self.get_approved(token_id) == spender
        }

        ////////////////////////////////
        // internal function that sets the token uri
        ////////////////////////////////
        fn _set_token_uri(ref self: ContractState, token_id: u256, token_uri: felt252) {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self.token_uri.write(token_id, token_uri)
        }

        ////////////////////////////////
        // internal function that performs the transfer logic
        ////////////////////////////////
        fn _transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            // check that from address is equal to owner of token
            assert(from == self.owner_of(token_id), 'ERC721: Caller is not owner');
            // check that to address is not zero
            assert(to.is_non_zero(), 'ERC721: transfer to 0 address');

            // remove previously made approvals
            self.token_approvals.write(token_id, Zero::zero());

            // increase balance of to address, decrease balance of from address
            self.balances.write(from, self.balances.read(from) - 1.into());
            self.balances.write(to, self.balances.read(to) + 1.into());

            // update token_id owner
            self.owners.write(token_id, to);

            // emit the Transfer event
            self.emit(Transfer { from: from, to: to, token_id: token_id });
        }

        ////////////////////////////////
        // _mint function mints a new token to the to address
        ////////////////////////////////
        fn _mint(ref self: ContractState, to: ContractAddress) {
            assert(to.is_non_zero(), 'TO_IS_ZERO_ADDRESS');

            // Generate token_id from an increment of total NFT count
            // ID starts from 1
            let prev_count = self.counter.read();
            let token_id: u256 = prev_count + 1;

            // Ensures token_id is unique
            assert(!self.owner_of(token_id).is_non_zero(), 'ERC721: Token already minted');

            // Increase receiver balance
            let receiver_balance = self.balances.read(to);
            self.balances.write(to, receiver_balance + 1.into());

            // Update token_id owner
            self.owners.write(token_id, to);

            // Update total NFT count
            self.counter.write(token_id);

            // Update token ids of address
            // A nested mapping is used to track the ids of tokens an address has
            // Another variable is used to track the number of ids
            let token_count_of_address = self.token_count_of_address.read(to);
            self.token_ids_of_address.write((to, token_count_of_address), token_id);
            // incremenet token count of address
            self.token_count_of_address.write(to, token_count_of_address + 1);

            // emit Transfer event
            self.emit(Transfer { from: Zero::zero(), to: to, token_id: token_id });
        }

        ////////////////////////////////
        // _burn function burns token from owner's account
        ////////////////////////////////
        fn _burn(ref self: ContractState, token_id: u256) {
            let owner = self.owner_of(token_id);

            // Clear approvals
            self.token_approvals.write(token_id, Zero::zero());

            // Decrease owner balance
            let owner_balance = self.balances.read(owner);
            self.balances.write(owner, owner_balance - 1.into());

            // Delete owner
            self.owners.write(token_id, Zero::zero());
            // emit the Transfer event
            self.emit(Transfer { from: owner, to: Zero::zero(), token_id: token_id });
        }
    }
}
