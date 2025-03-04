module {
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
};
