/**
 *Submitted for verification at Etherscan.io on 2020-10-14
*/

// ┏━━━┓━┏┓━┏┓━━┏━━━┓━━┏━━━┓━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━┏┓━━━━━┏━━━┓━━━━━━━━━┏┓━━━━━━━━━━━━━━┏┓━
// ┃┏━━┛┏┛┗┓┃┃━━┃┏━┓┃━━┃┏━┓┃━━━━┗┓┏┓┃━━━━━━━━━━━━━━━━━━┏┛┗┓━━━━┃┏━┓┃━━━━━━━━┏┛┗┓━━━━━━━━━━━━┏┛┗┓
// ┃┗━━┓┗┓┏┛┃┗━┓┗┛┏┛┃━━┃┃━┃┃━━━━━┃┃┃┃┏━━┓┏━━┓┏━━┓┏━━┓┏┓┗┓┏┛━━━━┃┃━┗┛┏━━┓┏━┓━┗┓┏┛┏━┓┏━━┓━┏━━┓┗┓┏┛
// ┃┏━━┛━┃┃━┃┏┓┃┏━┛┏┛━━┃┃━┃┃━━━━━┃┃┃┃┃┏┓┃┃┏┓┃┃┏┓┃┃━━┫┣┫━┃┃━━━━━┃┃━┏┓┃┏┓┃┃┏┓┓━┃┃━┃┏┛┗━┓┃━┃┏━┛━┃┃━
// ┃┗━━┓━┃┗┓┃┃┃┃┃┃┗━┓┏┓┃┗━┛┃━━━━┏┛┗┛┃┃┃━┫┃┗┛┃┃┗┛┃┣━━┃┃┃━┃┗┓━━━━┃┗━┛┃┃┗┛┃┃┃┃┃━┃┗┓┃┃━┃┗┛┗┓┃┗━┓━┃┗┓
// ┗━━━┛━┗━┛┗┛┗┛┗━━━┛┗┛┗━━━┛━━━━┗━━━┛┗━━┛┃┏━┛┗━━┛┗━━┛┗┛━┗━┛━━━━┗━━━┛┗━━┛┗┛┗┛━┗━┛┗┛━┗━━━┛┗━━┛━┗━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.6.11;

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

// Based on official specification in https://eips.ethereum.org/EIPS/eip-165
interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceId` and
    ///  `interfaceId` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
}

// This is a rewrite of the Vyper Eth2.0 deposit contract in Solidity.
// It tries to stay as close as possible to the original source code.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
contract DepositContract is IDepositContract, ERC165 {
    uint constant DEPOSIT_CONTRACT_TREE_DEPTH = 32;
    // NOTE: this also ensures `deposit_count` will fit into 64-bits
    uint constant MAX_DEPOSIT_COUNT = 2**DEPOSIT_CONTRACT_TREE_DEPTH - 1;

    bytes32[DEPOSIT_CONTRACT_TREE_DEPTH] branch;
    uint256 deposit_count;

    bytes32[DEPOSIT_CONTRACT_TREE_DEPTH] zero_hashes;

    constructor() public {
        // Compute hashes in empty sparse Merkle tree
        for (uint height = 0; height < DEPOSIT_CONTRACT_TREE_DEPTH - 1; height++)
            zero_hashes[height + 1] = sha256(abi.encodePacked(zero_hashes[height], zero_hashes[height]));
    }

    function get_deposit_root() override external view returns (bytes32) {
        bytes32 node;
        uint size = deposit_count;
        for (uint height = 0; height < DEPOSIT_CONTRACT_TREE_DEPTH; height++) {
            if ((size & 1) == 1)
                node = sha256(abi.encodePacked(branch[height], node));
            else
                node = sha256(abi.encodePacked(node, zero_hashes[height]));
            size /= 2;
        }
        return sha256(abi.encodePacked(
            node,
            to_little_endian_64(uint64(deposit_count)),
            bytes24(0)
        ));
    }

    function get_deposit_count() override external view returns (bytes memory) {
        return to_little_endian_64(uint64(deposit_count));
    }

    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) override external payable {
        // Extended ABI length checks since dynamic types are used.
        require(pubkey.length == 48, "DepositContract: invalid pubkey length");
        require(withdrawal_credentials.length == 32, "DepositContract: invalid withdrawal_credentials length");
        require(signature.length == 96, "DepositContract: invalid signature length");

        // Check deposit amount
        require(msg.value >= 1 ether, "DepositContract: deposit value too low");
        require(msg.value % 1 gwei == 0, "DepositContract: deposit value not multiple of gwei");
        uint deposit_amount = msg.value / 1 gwei;
        require(deposit_amount <= type(uint64).max, "DepositContract: deposit value too high");

        // Emit `DepositEvent` log
        bytes memory amount = to_little_endian_64(uint64(deposit_amount));
        emit DepositEvent(
            pubkey,
            withdrawal_credentials,
            amount,
            signature,
            to_little_endian_64(uint64(deposit_count))
        );

        // Compute deposit data root (`DepositData` hash tree root)
        bytes32 pubkey_root = sha256(abi.encodePacked(pubkey, bytes16(0)));
        bytes32 signature_root = sha256(abi.encodePacked(
            sha256(abi.encodePacked(signature[:64])),
            sha256(abi.encodePacked(signature[64:], bytes32(0)))
        ));
        bytes32 node = sha256(abi.encodePacked(
            sha256(abi.encodePacked(pubkey_root, withdrawal_credentials)),
            sha256(abi.encodePacked(amount, bytes24(0), signature_root))
        ));

        // Verify computed and expected deposit data roots match
        require(node == deposit_data_root, "DepositContract: reconstructed DepositData does not match supplied deposit_data_root");

        // Avoid overflowing the Merkle tree (and prevent edge case in computing `branch`)
        require(deposit_count < MAX_DEPOSIT_COUNT, "DepositContract: merkle tree full");

        // Add deposit data root to Merkle tree (update a single `branch` node)
        deposit_count += 1;
        uint size = deposit_count;
        for (uint height = 0; height < DEPOSIT_CONTRACT_TREE_DEPTH; height++) {
            if ((size & 1) == 1) {
                branch[height] = node;
                return;
            }
            node = sha256(abi.encodePacked(branch[height], node));
            size /= 2;
        }
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

    function supportsInterface(bytes4 interfaceId) override external pure returns (bool) {
        return interfaceId == type(ERC165).interfaceId || interfaceId == type(IDepositContract).interfaceId;
    }

    function to_little_endian_64(uint64 value) internal pure returns (bytes memory ret) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }
}
As a low cost and use-as-needed ERP system WebKOBIS ERP3 comes in TRADE, CRM, ERP, MRP, SMS, PMS, QMS, DMS, DAM, PAM, LMS, WSH, CMS, HRM, TMS  package editions which are providing over 35 main, over 75 integrated management modules for your business.

WebKOBIS ERP3' simple to use design, extensive database allows you to capture more details than most similar software would capture for your business.     



ADVANTAGES:

* Based on low cost web based proven technologies therefore effortable for most businesses.
* Integrate Advance Activity-Based Production, Process-Based Quality Assurance Support, Design Tracking, Sales & Marketing and other operational activities in one system easily.
* Control your connections and operations in an integrated & centralized framework.
* Upscale WebKOBIS ERP3 as easy as turning your light switch on according to your needs from TRADE to CRM or from TRADE to ERP or from CRM to ERP edition.
* WebKOBIS ERP3 SaaS licence you save money from expensive hardware, software and backup support. WebKOBIS ERP3 will be ready for you anytime you need.
* WebKOBIS ERP3' standard editions can be expanded for specialized systems with additional Optional Modules according to your needs.
* WebKOBIS ERP3' Optional B2B modules provide quick and specialized solutions for your B2B needs without changing your core WebKOBIS ERP3 application. Utilizing WebKOBIS ERP3 B2B modules you can establish Customer or Vendor online service systems quickly as well as Mobile access portals for your field personnel..
* With WebKOBIS ERP3 you don't have to do long term contracts. Accounts are annual & you pay as long as you use. However you can get WebKOBIS ERP3 benefits for your long term contract requests. 
* Your data is yours. If you decide to end your WebKOBIS ERP3 account, your database will be delivered to you. In fact you can download your data whenever you want.


* WebKOBIS ERP3 centralize and integrates your all activities such as Production, Procurement, Sales and Quality Assurance assuring simultaneous awareness between related departments and users.
* WebKOBIS ERP3 allows you to create customized dashboards as many as you need using already defined charts. This allows you to focus to your area of interest.
* WebKOBIS ERP3' role/group based user access security system allows you to control knowledge security more effectively.
* WebKOBIS ERP3' dynamic filtering and Advance Search ability gives you to search on all fields in your database allowing you to do dynamic analysis of your data. 
* All Reports and Graphics in WebKOBIS ERP3 allows you filter and search data so you can dynamically analyse your data.
* WebKOBIS ERP3 uses 8 important security mechanism. As an example you can define User/IP addresses to WebKOBIS ERP3 to limit their log in; even log in date & time. 



WebKOBIS ERP3 MAIN MODULES:

* Agenda Management
* Call Center Management 
* Contact Management
* Customer Management
* Sales Management 
* Orders Management 
* Proposal Management 
* Contract Management 
* Competitor Firm Management 
* Potential Sales
* Product Management
* Production Management 
* Quality Management 
* Activity Management
* Stock Management
* Logistic Management
* Vendor Management
* Procurement Management
* Potential Procurements
* Work Order Management
* Financial Management
* Expense Management
* Payment Management
* Asset Management
* Vehicle  Management
* Repair Management
* Document Management
* Training Management
* Knowledge Base Management
* Foreign Trade Management
* Dashboards Management
 


WebKOBIS ERP3 Additional Modules:
* Advance Production Planing & Management (WKB-UP)
* Product Design & Sample Management (WKB-UT)
* Product Casting & Sample Management (WKB-UD)
* Business Planning & Project Management System (WKB-IP)
* Human Resources Management  (WKB-IK)
* Work Safety Management  (WKB-IG)
* Business Intelligence Reporting System (WKB-RP)
* phpMyAdmin integration 


WebKOBIS ERP3 Additional B2B Modules:
* Production Tracking Portal (WKB-IT)
* Customer/Partner B2B Portal (WKB-MP)
* Vendor B2B Portal (WKB-TP)
* Mobile Phone / Mobile Access Portal (WKB-CP)
* Web Site Integration Module(WKB-WS)
* Shopping Cart Integration (WKB-IM)

 
WebKOBIS ERP3 Financial System Gateway Modules:
* ETA:V8.SQL (WKB-FS/ETA)




MORE DETAILS: 


WebKOBIS ERP3 ERP is an ERP cloud service that covers all business, especially production processes for small to large-sized companies.


WebKOBIS ERP3 SaaS LICENCE

* Standard WebKOBIS ERP3 installation with optional modüles purchased
* Low cost SaaS licence with dedicated instalation
* Daily Data Backups
* Project based customization for your business demand



WebKOBIS ERP3 GENERAL FEATURES

* Windows-like Role based dynamic Menu
* Over 525 List forms supporting Quick Data Links, Data filtering and Advance Searches 
* Hihgly detailed database tables
* Comprehensive 360 Business Logic
* Role/Group base Access Management
* 400+ Analysis Charts with dynamic filtering
* 100+ Reports with dynamic filtering
* Over 500 forms with dynamic filtering and detailed search for Dynamic Reporting 
* User Defineable Dashborads from Analysis Charts; 50+ standard Dashboards to analize modules 
* Over 140 User definable Notification Widgets 
* Encrypted communication
* Integrated firewall for user/IP and access date/time schedule
* Integrated support for GoogleMaps
* Integrated Gantt Charts and calendars
* Export (.csv, .doc, .xls, .xml, .pdf)  
* Add-On module support for better business integration
	-Advance Production Tracking System
	-Customer B2B System
	-Vendor B2B System
	-Mobile Personnel Access System



SALES AND CRM
* Complete sales management
* Call Center processing
* Potentials Management
* Pre-sales processing
* One click converting process (Lead-Opportunity-Quotation-Invoice-Payment-Delivery)
* Currency management engine for automatic currency conversion 
* Tax Engine manages multiple tax types
* Various payment terms
* Customizable notes 
* Customer Returns
* Competitor Management 



PURCHASING AND SUPPLIER MANAGEMENT
* Accumulating various purchase ordertypes from various processing engines
* Manual or automatic purchase management according to business needs
* Various payment types
* Supplier returns
* Various payment terms
* Consignment management


PRODUCT MANAGEMENT & PRODUCTION
* Standard Product Management Module depending on business demands
* Standard Product Material Tree 
* BOM/Component based production
* Recurring production
* Services


ADVANCE PRODUCTION
* Advance Product & Production Management module depending on business demands
* Multi-site, multi-line, solid or virtual assembly lines
* Project management with Gantt chart
* Product Variant Engince
* Detailed activity based production with detailed process definitioins  
* BOM/Component based production
* Activity based Production Tracking 
* MRP Support
* Production Needs
* Recurring production
* Time-managed production
* Product Design Tracking
* Product Sampling Tracking
* Product Casting Tracking



QUALITY ASSURANCE
* Quality Assurance Document (Plans, Forms, Specs)
* Detailed activity-based process defitions
* Process-QA Definitions links 
* QA Test Plans & Tests
* QA Activities Tracking


WORK ORDERS
* Work Orders tracking for 
	-Customer Services
	-Production
	-Quality Assurance Activity
	-Repair Services
	-Logistics
	-Precurement
	-WorkSafety
* Integrated Cost tracing 


DOCUMENT MANAGEMENT
* Document Integration to various modules such as products, Financials, Quality Assurance, Sales etc
* Upload as File or Upload In to Database options 
* Archive Management


WAREHOUSE AND INVENTORY CONTROL
* Real-time inventory
* Easy tracking low stocks or stocks under Low-Level settings 
* Document linking
* Detailed product definitions (Images, SKU, barcode, manual linking, categories, trademarks)
* Internal deliveries
* Multiple-warehouses


FINANCE AND ACCOUNTING
* Payables and receivables, with real-time invoice support
* Fixed Asset Management
* Financial Dashboards, Reporting and Analytics
* More than 100 standard reports
* Payment Management
* DDocument linking (invoice Send, supplier invoice received)
* Payments Management
* Expence  Management


BUSINESS PLANS & PROJECT PLANNING
* Integrated Business Plans & Details to track high level & project level progress
* Integrated Project Plans & Details  to Track all-arround business activities 
* Easy Project-based cost, Sales, precurement, payment, workorder tracking  


BUSINESS INTELLIGENCE
* Dynamic Reporting & Analyzing with Report Management Module 
* 400+ Analysis Charts with dynamic filtering
* 100+ Reports with dynamic filtering
* Over 525 List forms supporting Quick Data Links, Data filtering and Advance Searches 
* User Defineable Dashborads from Analysis Charts; 50+ standard Dashboards to analize modules 
* Over 140 User definable Notification Widgets 
* Export (.csv, .doc, .xls, .xml, .pdf)  
* Quick Data Links 
* Send emails 
* Module Dashboard 
* Role based reporting



HUMAN RESOURCES
* Detailed Personnel records
* Personnel Leaves, Reports
* Roles, Work Assignments and Performance tracking 
* Personnel Evaluations
* Open roles & Applications management
* Timesheet tracking
 

WORK, SAFETY & HEALTH
* Integrated Work & Safety Module
* Integrated Worker Health Module
* Risc Tracking
