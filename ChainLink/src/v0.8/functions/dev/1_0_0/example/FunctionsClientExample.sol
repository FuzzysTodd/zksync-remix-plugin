/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/ChainLink?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "../FunctionsClient.sol";
import {Functions} from "../Functions.sol";
import {ConfirmedOwner} from "../../../../ConfirmedOwner.sol";

/**
 * @title Chainlink Functions example client contract implementation
 */
contract FunctionsClientExample is FunctionsClient, ConfirmedOwner {
  using Functions for Functions.Request;

  uint32 public constant MAX_CALLBACK_GAS = 70_000;

  bytes32 public s_lastRequestId;
  bytes32 public s_lastResponse;
  bytes32 public s_lastError;
  uint32 public s_lastResponseLength;
  uint32 public s_lastErrorLength;

  error UnexpectedRequestID(bytes32 requestId);

  constructor(address router) FunctionsClient(router) ConfirmedOwner(msg.sender) {}

  /**
   * @notice Send a simple request
   * @param source JavaScript source code
   * @param encryptedSecretsReferences Encrypted secrets payload
   * @param args List of arguments accessible from within the source code
   * @param subscriptionId Billing ID
   */
  function sendRequest(
    string calldata source,
    bytes calldata encryptedSecretsReferences,
    string[] calldata args,
    uint64 subscriptionId,
    bytes32 jobId
  ) external onlyOwner {
    Functions.Request memory req;
    req.initializeRequestForInlineJavaScript(source);
    if (encryptedSecretsReferences.length > 0) req.addSecretsReference(encryptedSecretsReferences);
    if (args.length > 0) req.setArgs(args);
    s_lastRequestId = _sendRequest(req, subscriptionId, MAX_CALLBACK_GAS, jobId);
  }

  /**
   * @notice Store latest result/error
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
    if (s_lastRequestId != requestId) {
      revert UnexpectedRequestID(requestId);
    }
    // Save only the first 32 bytes of response/error to always fit within MAX_CALLBACK_GAS
    s_lastResponse = bytesToBytes32(response);
    s_lastResponseLength = uint32(response.length);
    s_lastError = bytesToBytes32(err);
    s_lastErrorLength = uint32(err.length);
  }

  function bytesToBytes32(bytes memory b) private pure returns (bytes32 out) {
    uint256 maxLen = 32;
    if (b.length < 32) {
      maxLen = b.length;
    }
    for (uint256 i = 0; i < maxLen; ++i) {
      out |= bytes32(b[i]) >> (i * 8);
    }
    return out;
  }
}
