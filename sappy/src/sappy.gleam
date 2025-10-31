import sappy/endpoint

pub const client_create_request = endpoint.client_create_request

/// **NOTE:** Generally, you should not need to call this function directly.
///
/// *Instead*, use a library such as sappy_wisp to handle requests directly in the framework you are using.
/// 
/// Returns:
///  - a function that, given the body of a request, converts it into the input specified in the endpoint definition
///  - an optional function that converts the output specified in the endpoint definition into a response body
pub const server_handle_request = endpoint.server_handle_request

pub const client_handle_response = endpoint.client_handle_response
