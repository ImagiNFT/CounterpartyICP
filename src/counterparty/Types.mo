import Text "mo:base/Text";
module {
    public type fetch_methods = { #get; #head; #post };

    public type http_header = { name : Text; value : Text };
    public type http_request_args = {
        body : ?Blob;
        headers : [http_header];
        max_response_bytes : ?Nat64;
        method : { #get; #head; #post };
        transform : ?{
            context : Blob;
            function : shared query {
                context : Blob;
                response : http_request_result;
            } -> async http_request_result;
        };
        url : Text;
    };
    public type http_request_result = {
        body : Blob;
        headers : [http_header];
        status : Nat;
    };

    public type IC = actor {
        http_request : http_request_args -> async http_request_result;
    };

    public type ConsensuedResponse = {
        in_consensus: Bool;
        consensus_percentage: Nat;
        nodes_checked: Nat;
        consensus_endpoints: [Text];
        out_of_consensus_endpoints: [Text];
        response: Text;
    }
};
