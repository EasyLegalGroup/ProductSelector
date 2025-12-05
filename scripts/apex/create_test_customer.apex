// Diagnostic: Try to create customer in test Reepay account
// Get the test key for Din_Familiejurist
Price_Book__mdt pbConfig = [SELECT Encoded_Private_Key__c, Test_Encoded_Private_Key__c, Internal_Identifier__c 
                            FROM Price_Book__mdt 
                            WHERE Internal_Identifier__c = 'Din_Familiejurist' LIMIT 1];

System.debug('Has Test Key: ' + String.isNotBlank(pbConfig.Test_Encoded_Private_Key__c));

// Try to GET the customer first
HttpRequest getReq = new HttpRequest();
getReq.setEndpoint('https://api.reepay.com/v1/customer/awd98hawd@awd98hanwawdawd.com');
getReq.setMethod('GET');
getReq.setHeader('Authorization', 'Basic ' + pbConfig.Test_Encoded_Private_Key__c);
getReq.setHeader('Accept', 'application/json');
getReq.setTimeout(120000);

Http http = new Http();
HttpResponse getResp = http.send(getReq);
System.debug('GET Customer Status: ' + getResp.getStatusCode());
System.debug('GET Customer Response: ' + getResp.getBody());

// If customer doesn't exist (404), create them
if (getResp.getStatusCode() == 404) {
    System.debug('Customer not found, creating...');
    
    HttpRequest createReq = new HttpRequest();
    createReq.setEndpoint('https://api.reepay.com/v1/customer');
    createReq.setMethod('POST');
    createReq.setHeader('Authorization', 'Basic ' + pbConfig.Test_Encoded_Private_Key__c);
    createReq.setHeader('Accept', 'application/json');
    createReq.setHeader('Content-Type', 'application/json');
    createReq.setTimeout(120000);
    
    // Create customer request body
    String customerBody = '{"handle":"awd98hawd@awd98hanwawdawd.com","email":"awd98hawd@awd98hanwawdawd.com","first_name":"Mathias","last_name":"Demo Demo2","test":true}';
    createReq.setBody(customerBody);
    
    HttpResponse createResp = http.send(createReq);
    System.debug('CREATE Customer Status: ' + createResp.getStatusCode());
    System.debug('CREATE Customer Response: ' + createResp.getBody());
} else {
    System.debug('Customer already exists in test account');
}
