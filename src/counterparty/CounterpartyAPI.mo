import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Nat "mo:base/Nat";
import Random "mo:base/Random";
import UUID "mo:idempotency-keys/idempotency-keys";
import Types "Types";
import Option "mo:base/Option";

actor {
  let counterparty_endpoint = "https://counterparty.0.srcpad.pro";

  type BalanceType = {
    #all;
    #utxo;
    #address;
  };

  private func getBalanceType(balanceType : BalanceType) : Text {
    let balanceTypeText = switch (balanceType) {
      case (#all) { "all" };
      case (#utxo) { "utxo" };
      case (#address) { "address" };
    };
    balanceTypeText;
  };

  type OrderStatus = {
    #all;
    #open;
    #expired;
    #filled;
    #canceled;
  };

  private func getOrderStatus(status : OrderStatus) : Text {
    let orderStatusText = switch (status) {
      case (#all) { "all" };
      case (#open) { "open" };
      case (#expired) { "expired" };
      case (#filled) { "filled" };
      case (#canceled) { "canceled" };
    };
    orderStatusText;
  };

  type DispenserStatus = {
    #all;
    #open;
    #closed;
    #closing;
    #open_empty_address;
  };

  private func getDispenserStatus(status : DispenserStatus) : Text {
    let dispenserStatusText = switch (status) {
      case (#all) { "all" };
      case (#open) { "open" };
      case (#closed) { "closed" };
      case (#closing) { "closing" };
      case (#open_empty_address) { "open_empty_address" };
    };
    dispenserStatusText;
  };

  type FairminterStatus = {
    #all;
    #open;
    #closed;
    #pending;
  };

  private func getFairminterStatus(status : FairminterStatus) : Text {
    let fairminterStatusText = switch (status) {
      case (#all) { "all" };
      case (#open) { "open" };
      case (#closed) { "closed" };
      case (#pending) { "pending" };
    };
    fairminterStatusText;
  };

  type BetStatus = {
    #cancelled;
    #dropped;
    #expired;
    #filled;
    #open;
    #pending;
  };

  private func getBetStatus(status : BetStatus) : Text {
    let betStatusText = switch (status) {
      case (#cancelled) { "cancelled" };
      case (#dropped) { "dropped" };
      case (#expired) { "expired" };
      case (#filled) { "filled" };
      case (#open) { "open" };
      case (#pending) { "pending"};
    };
    betStatusText;
  };

  type AssetEventType = {
    #all;
    #creation;
    #reissuance;
    #lock_quantity;
    #reset;
    #change_description;
    #transfer;
    #open_fairminter;
    #fairmint;
    #lock_description;
  };

  private func getAssetEventType(event : AssetEventType) : Text {
    let assetEventsText = switch (event) {
      case (#all) { "all" };
      case (#creation) { "creation" };
      case (#reissuance) { "reissuance" };
      case (#lock_quantity) { "lock_quantity" };
      case (#reset) { "reset" };
      case (#change_description) { "change_description" };
      case (#transfer) { "transfer" };
      case (#open_fairminter) { "open_fairminter" };
      case (#fairmint) { "fairmint" };
      case (#lock_description) { "lock_description" };
    };
    assetEventsText;
  };

  let commonHttpHeaders = [
    {
      name = "User-Agent";
      value = "ICP_CANISTER";
    },
    {
      name = "Content-Type";
      value = "application/json";
    },
  ];

  var entropy : Blob = Blob.fromArray([]);

  private func initEntropy() : async () {
    entropy := await Random.blob();
  };

  public query func transform({
    context : Blob;
    response : Types.http_request_result;
  }) : async Types.http_request_result {
    {
      response with headers = [];
    };
  };

  private func generateUUID() : async Text {
    if (Blob.compare(entropy, Blob.fromArray([])) == #equal) {
      await initEntropy();
    };
    UUID.generateV4(entropy);
  };

  private func fetch(url : Text, method : { #get; #head; #post }, body : ?Blob) : async Text {
    let ic : Types.IC = actor ("aaaaa-aa");
    let idempotencyHeader = {
      name = "Idempotency-Key";
      value = await generateUUID();
    };
    let httpHeaders = Array.append(commonHttpHeaders, [idempotencyHeader]);
    let request : Types.http_request_args = {
      url = url;
      max_response_bytes = null;
      headers = httpHeaders;
      body = body;
      method = method;
      transform = ?{
        function = transform;
        context = Blob.fromArray([]);
      };
    };
    Cycles.add<system>(230_949_972_000);
    let response : Types.http_request_result = await ic.http_request(request);
    let decoded_text : Text = switch (Text.decodeUtf8(response.body)) {
      case (null) { "No value returned" };
      case (?y) { y };
    };
    decoded_text;
  };

  public func getAssets(
    named : ?Bool,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_named = Option.get(named, false);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets?named=" # Bool.toText(final_named)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getAssetInfo(
    asset : Text,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);
    let url = counterparty_endpoint # "/v2/assets/"
    # asset # "?verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getAssetBalances(
    asset : Text,
    balanceType : ?BalanceType,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_balanceType = Option.get(balanceType, #all);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset
    # "/balances?type=" # getBalanceType(final_balanceType)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getBalancesByAssetAndAddress(
    asset : Text,
    address : Text,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);
    let url = counterparty_endpoint # "/v2/assets/" # asset # "/balances/" # address
    # "?verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getOrdersByAsset(
    asset : Text,
    status : ?OrderStatus,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_status = Option.get(status, #all);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/orders"
    # "?status=" # getOrderStatus(final_status)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getOrderMatchesByAsset(
    asset : Text,
    status : ?OrderStatus,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_status = Option.get(status, #all);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/matches"
    # "?status=" # getOrderStatus(final_status)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getCreditsByAsset(
    asset : Text,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/credits"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getDebitsByAsset(
    asset : Text,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/debits"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getDividendsByAsset(
    asset : Text,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/dividends"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getIssuancesByAsset(
    asset : Text,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/issuances"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getSendsByAsset(
    asset : Text,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/sends"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getDispensersByAsset(
    asset : Text,
    status : ?DispenserStatus,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_status = Option.get(status, #all);
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/debits"
    # "?status=" # getDispenserStatus(final_status)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getDispenserByAddressAndAsset(
    address : Text,
    asset : Text,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/dispensers/" # address
    # "?verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getAssetHolders(
    asset : Text,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/holders"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getDispensesByAsset(
    asset : Text,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/dispenses"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getSubassetsByAsset(
    asset : Text,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/subassets"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getFairmintersByAsset(
    asset : Text,
    status : ?FairminterStatus,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_status = Option.get(status, #all);
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/fairminters"
    # "?status=" # getFairminterStatus(final_status)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getFairmintsByAsset(
    asset: Text,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/fairmints"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

    public func getFairmintsByAddressAndAsset(
    asset: Text,
    address: Text,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset # "/fairmints" # address
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getOrders(
    status: ?OrderStatus,
    get_asset: ?Text,
    give_asset: ?Text,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_status = Option.get(status, #all);
    let final_get_asset = Option.get(get_asset, "None");
    let final_give_asset = Option.get(give_asset, "None");
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/orders"
    # "?status=" # getOrderStatus(final_status)
    # "&get_asset=" # final_get_asset
    # "&give_asset=" # final_give_asset
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getOrder(
    order_hash: Text,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/orders/" # order_hash
    # "?verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getOrderMatchesByOrder(
    order_hash: Text,
    status: ?OrderStatus,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_status = Option.get(status, #all);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/orders/" # order_hash # "/matches"
    # "?status=" # getOrderStatus(final_status)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getBTCPaysByOrder(
    order_hash: Text,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/orders/" # order_hash # "/btcpays"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getOrdersByTwoAssets(
    asset1: Text,
    asset2: Text,
    status: ?OrderStatus,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ):async Text{
    let final_status = Option.get(status, #all);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/orders/" # asset1 # "/" # asset2
    # "?status=" # getOrderStatus(final_status)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getAllOrderMatches(
    status: ?OrderStatus,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ):async Text{
    let final_status = Option.get(status, #all);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/order_matches"
    # "?status=" # getOrderStatus(final_status)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getBets(
    status: ?BetStatus,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text{
    let final_status = Option.get(status, #open);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/bets"
    # "?status=" # getBetStatus(final_status)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getBet(
    bet_hash: Text,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/bets/" # bet_hash
    # "?verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getBetMatchesByBet(
    bet_hash: Text,
    status: ?BetStatus,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ) : async Text {
    let final_status = Option.get(status, #pending);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/bets/" # bet_hash # "/matches"
    # "?status=" # getBetStatus(final_status)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getResolutionsByBet(
    bet_hash: Text,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/bets/" # bet_hash # "/resolutions"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getAllBurns(
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/burns"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getDispensers(
    status: ?DispenserStatus,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_status = Option.get(status, #all);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);
    
    let url = counterparty_endpoint # "/v2/dispensers"
    # "?status=" # getDispenserStatus(final_status)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getDispenserInfoByHash(
    dispenser_hash: Text,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/dispensers/" # dispenser_hash
    # "?verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };
  
  public func getDispensesByDispenser(
    dispenser_hash: Text,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);
    
    let url = counterparty_endpoint # "/v2/dispensers/" # dispenser_hash # "/dispenses"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getDividends(
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);
    
    let url = counterparty_endpoint # "/v2/dividends"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getDividend(
    dividend_hash: Text,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);
    
    let url = counterparty_endpoint # "/v2/dividends/" # dividend_hash
    # "?verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };
  
  public func getDividendDistribution(
    dividend_hash: Text,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);
    
    let url = counterparty_endpoint # "/v2/dividends/" # dividend_hash # "/credits"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getDispenses(
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);
    
    let url = counterparty_endpoint # "/v2/dispenses"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getSends(
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/sends"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getIssuances(
    asset_events: ?AssetEventType,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_asset_events = Option.get(asset_events, #all);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/issuances"
    # "?asset_events=" # getAssetEventType(final_asset_events)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getIssuanceByTransactionHash(
    tx_hash: Text,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/issuances/" # tx_hash
    # "?verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getSweeps(
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ):async Text{
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);
    
    let url = counterparty_endpoint # "/v2/sweeps"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getSweepByTransactionHash(
    tx_hash: Text,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);
    
    let url = counterparty_endpoint # "/v2/sweeps/" # tx_hash
    # "?verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getValidBroadcasts(
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/broadcasts"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getBroadcastByTransactionHash(
    tx_hash: Text,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/broadcasts/" # tx_hash
    # "?verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getAllFairminters(
    status: ?FairminterStatus,
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text{
    let final_status = Option.get(status, #all);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/fairminters"
    # "?status=" # getFairminterStatus(final_status)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getAllFairmints(
    cursor: ?Text,
    limit: ?Nat,
    offset: ?Nat,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);
    
    let url = counterparty_endpoint # "/v2/fairmints"
    # "?cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);
    await fetch(url, #get, null);
  };

  public func getFairmint(
    tx_hash: Text,
    verbose: ?Bool,
    show_unconfirmed: ?Bool,
  ): async Text {
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint # "/v2/fairmints/" # tx_hash
    # "?verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func getBalancesByAddress(
    address : Text,
    balanceType : ?BalanceType,
    cursor : ?Text,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_balanceType = Option.get(balanceType, #all);
    let final_cursor = Option.get(cursor, "None");
    let final_limit = Option.get(limit, 100);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/addresses/balances"
    # "?addresses=" # address
    # "&type=" # getBalanceType(final_balanceType)
    # "&cursor=" # final_cursor
    # "&limit=" # Nat.toText(final_limit)
    # "&offset=" # Nat.toText(final_offset)
    # "&verbose=" # Bool.toText(final_verbose)
    # "&show_unconfirmed=" # Bool.toText(final_show_unconfirmed);

    await fetch(url, #get, null);
  };

  public func composeSend(
    address : Text,
    destination : Text,
    asset : Text,
    quantity : Nat,
    exclude_utxos_with_balances : Bool,
    use_enhanced_send : Bool,
    verbose : Bool,
  ) : async Text {
    let url = counterparty_endpoint # "/v2/addresses/" # address # "/compose/send"
    # "?asset=" # asset
    # "&use_enhanced_send=" # Bool.toText(use_enhanced_send)
    # "&address=" # address
    # "&verbose=" # Bool.toText(verbose)
    # "&destination=" # destination
    # "&quantity=" # Nat.toText(quantity)
    # "&exclude_utxos_with_balances=" # Bool.toText(exclude_utxos_with_balances);
    await fetch(url, #get, null);
  };

};
