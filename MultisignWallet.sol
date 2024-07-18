// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract MultiSigWallet {
    constructor() {
        //set admin address by default
        adminAddr = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    }

    struct Transaction {
        uint256 id;
        address initiator;
        uint256 amount;
        address payable destination;
        uint256 totalSignersApprovalRequired;
        uint256 totalSignersApproved;
    }

    struct Signer {
        address addr;
    }

    address private adminAddr;
    mapping(address => bool) private signers;
    uint256 private numSigners;
    Transaction[] public pendingTransfers;
    uint256 private MAX_SIGNERS = 5;
    uint256 private MIN_SIGNERS = 5;

    modifier onlyAdmin() {
        require(
            msg.sender == adminAddr,
            "You're not allowed to access this function"
        );
        _;
    }

    modifier onlySigner() {
        require(
            signers[msg.sender],
            "You're not allowed to access this function"
        );
        _;
    }

    function updateMaxSigners(uint256 _numSigners) public onlyAdmin {
        MAX_SIGNERS = _numSigners;
    }

    function updateMinSigners(uint256 _numSigners) public onlyAdmin {
        MIN_SIGNERS = _numSigners;
    }

    function setAdmin(address adminAddress) public onlyAdmin {
        adminAddr = adminAddress;
    }

    function addSigner(address signerAddr) public onlyAdmin {
        require(numSigners != MAX_SIGNERS, "Max number of signers reached");

        if (!signers[signerAddr]) {
            signers[signerAddr] = true;
            ++numSigners;
        }
    }

    function removeSigner(address signerAddr) public onlyAdmin {
        if (signers[signerAddr]) {
            delete signers[signerAddr];
            --numSigners;
        }
    }

    function transfer() public payable {
        //
    }

    function withdraw(uint256 amount, address payable reciepient) public {
        uint256 balance = getBalance();
        require(
            balance >= amount,
            "Not enough balance to fulfill withdrawal amount"
        );

        if (MIN_SIGNERS == 0) {
            //transfer immediately if no signers are required
            reciepient.transfer(amount);
            return;
        }

        pendingTransfers.push(
            Transaction({
                id: pendingTransfers.length,
                initiator: msg.sender,
                amount: amount,
                destination: reciepient,
                totalSignersApprovalRequired: MIN_SIGNERS,
                totalSignersApproved: 0
            })
        );
    }

    function approveSignTransaction(uint256 transactionId) public onlySigner {
        require(
            transactionId < pendingTransfers.length,
            "Transaction ID does not exist"
        );
        uint256 _numSigners = ++pendingTransfers[transactionId]
            .totalSignersApproved;
        if (
            _numSigners ==
            pendingTransfers[transactionId].totalSignersApprovalRequired
        ) {
            // perform the withdrawal transaction once the minimum number of approvals are reached
            pendingTransfers[transactionId].destination.transfer(
                pendingTransfers[transactionId].amount
            );
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
