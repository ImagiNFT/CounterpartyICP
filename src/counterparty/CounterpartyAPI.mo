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

  private func getBalanceType(balanceType : BalanceType) : Text {
    let balanceTypeText = switch (balanceType) {
      case (#all) { "all" };
      case (#utxo) { "utxo" };
      case (#address) { "address" };
    };
    balanceTypeText;
  };

  public func getAssets(
    named : ?Bool,
    cursor : ?Nat,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_named = Option.get(named, false);
    let final_cursor = Option.get(cursor, 0);
    let final_limit = Option.get(limit, 50);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets?named=" # Bool.toText(final_named)
    # "&cursor=" # Nat.toText(final_cursor)
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
    cursor : ?Nat,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_balanceType = Option.get(balanceType, #all);
    let final_cursor = Option.get(cursor, 0);
    let final_limit = Option.get(limit, 50);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/assets/" # asset
    # "/balances?type=" # getBalanceType(final_balanceType)
    # "&cursor=" # Nat.toText(final_cursor)
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

  public func getBalancesByAddress(
    address : Text,
    balanceType : ?BalanceType,
    cursor : ?Nat,
    limit : ?Nat,
    offset : ?Nat,
    verbose : ?Bool,
    show_unconfirmed : ?Bool,
  ) : async Text {
    let final_balanceType = Option.get(balanceType, #all);
    let final_cursor = Option.get(cursor, 0);
    let final_limit = Option.get(limit, 50);
    let final_offset = Option.get(offset, 0);
    let final_verbose = Option.get(verbose, false);
    let final_show_unconfirmed = Option.get(show_unconfirmed, false);

    let url = counterparty_endpoint
    # "/v2/addresses/balances"
    # "?addresses=" # address
    # "&type=" # getBalanceType(final_balanceType)
    # "&cursor=" # Nat.toText(final_cursor)
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
