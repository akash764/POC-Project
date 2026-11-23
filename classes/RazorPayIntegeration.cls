public class RazorPayIntegeration {
    
    public static void createOrders(Decimal amount){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('Callout:RazorPayNamedCredentials/v1/orders');
        request.setMethod('POST');
        request.setHeader('Content-Type','Application/json');
        Map<String,Object> payload = new Map<String,Object>();
        
        payload.put('amount', amount);
        payload.put('currency', 'INR');
        payload.put('receipt', 'PROP-1001');
        
        request.setBody(JSON.serialize(payload));
        
        try{
            HttpResponse response = http.send(request);
            System.debug('Status Code :'+response.getStatusCode());
            System.debug('response Body :'+response.getBody());
            if(response.getStatusCode() == 200){
                Map<String,Object> results = (Map<String,Object>)JSON.deserializeUntyped(response.getBody());
                String razorPayid = (String) results.get('id');
                System.debug('RazorPay Order Id :'+results.get('orderid'));
            }
            else{
                System.debug('RazorPay API Error '+response.getBody());
            }
            
        }catch(Exception e){
            System.debug('Callout Exception '+e.getMessage());
        }
    }
    
   
public static void createPayment(
    Decimal amount,
    String customerName,
    String phone,
    String email
) {

    if (amount == null || amount <= 0) {
        System.debug('Amount cannot be null or zero');
        return;
    }

    Http http = new Http();
    HttpRequest request = new HttpRequest();

    request.setEndpoint(
        'callout:RazorPayNamedCredentials/v1/payment_links'
    );

    request.setMethod('POST');

    request.setHeader(
        'Content-Type',
        'application/json'
    );

    // Convert Rupees into Paise
    Integer amountInPaise =
        (Integer)(amount * 100);

    // Customer details
    Map<String, Object> customer =
        new Map<String, Object>();

    customer.put('name', customerName);
    customer.put('contact', phone);
    customer.put('email', email);

    // Main request payload
    Map<String, Object> payload =
        new Map<String, Object>();

    payload.put('amount', amountInPaise);
    payload.put('currency', 'INR');
    payload.put(
        'description',
        'Property Booking Payment'
    );

    payload.put('customer', customer);

    request.setBody(JSON.serialize(payload));

    System.debug('Request Payload: ' + request.getBody());

    try {

        HttpResponse response = http.send(request);

        System.debug(
            'Status Code: ' + response.getStatusCode()
        );

        System.debug(
            'Response Body: ' + response.getBody()
        );

        if (
            response.getStatusCode() == 200 ||
            response.getStatusCode() == 201
        ) {

            Map<String, Object> results =
                (Map<String, Object>)
                JSON.deserializeUntyped(response.getBody());

            String razorPayId =
                (String)results.get('id');

            String paymentLink =
                (String)results.get('short_url');

            System.debug('Payment Link ID: ' + razorPayId);

            System.debug('Payment URL: ' + paymentLink);

        } else {

            System.debug(
                'Payment Failed: ' + response.getBody()
            );
        }

    } catch (Exception e) {

        System.debug(
            'Callout Exception: ' + e.getMessage()
        );
    }
}
    
   /* public static void createUpiPayment(
    Decimal amount,
    String customerName,
    String phone,
    String email
) {

    if (amount == null || amount <= 0) {
        System.debug('Amount cannot be null or zero');
        return;
    }

    Http http = new Http();
    HttpRequest request = new HttpRequest();

    request.setEndpoint(
        'callout:RazorPayNamedCredentials/v1/payment_links'
    );

    request.setMethod('POST');

    request.setHeader(
        'Content-Type',
        'application/json'
    );

    // Convert Rupees into Paise
    Integer amountInPaise =
        (Integer)(amount * 100);

    // Customer details
    Map<String, Object> customer =
        new Map<String, Object>();

    customer.put('name', customerName);
    customer.put('contact', phone);
    customer.put('email', email);

    // Main request payload
    Map<String, Object> payload =
        new Map<String, Object>();

    payload.put('amount', amountInPaise);
    payload.put('currency', 'INR');
    //payload.put('upi_link',true);
    payload.put(
        'description',
        'Property Booking Payment'
    );

    payload.put('customer', customer);

    request.setBody(JSON.serialize(payload));

    System.debug('Request Payload: ' + request.getBody());

    try {

        HttpResponse response = http.send(request);

        System.debug(
            'Status Code: ' + response.getStatusCode()
        );

        System.debug(
            'Response Body: ' + response.getBody()
        );

        if (
            response.getStatusCode() == 200 ||
            response.getStatusCode() == 201
        ) {

            Map<String, Object> results =
                (Map<String, Object>)
                JSON.deserializeUntyped(response.getBody());

            String razorPayId =
                (String)results.get('id');

            String paymentLink =
                (String)results.get('short_url');

            System.debug('UPI Payment Link ID: ' + razorPayId);

            System.debug('UPI Payment URL: ' + paymentLink);

        } else {

            System.debug(
                'Payment Failed: ' + response.getBody()
            );
        }

    } catch (Exception e) {

        System.debug(
            'Callout Exception: ' + e.getMessage()
        );
    }
}*/
    
}