@IsTest
private class WhatsAppWebhookTest {

   
    private static void prepareGetRequest(
        String token,
        String challenge
    ) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/whatsapp/webhooks/v1/';
        req.httpMethod = 'GET';

        req.params.put('hub.verify_token', token);

        if (challenge != null) {
            req.params.put('hub.challenge', challenge);
        }

        RestContext.request = req;
        RestContext.response = res;
    }

    
    private static void preparePostRequest(
        String body,
        Boolean validSignature
    ) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/whatsapp/webhooks/v1/';
        req.httpMethod = 'POST';

        req.requestBody = Blob.valueOf(body);

        if (validSignature) {

            Blob mac = Crypto.generateMac(
                'hmacSHA256',
                req.requestBody,
                Blob.valueOf(System.Label.FBAppSecert.trim())
            );

            String signature =
                'sha256=' + EncodingUtil.convertToHex(mac);

            req.headers.put(
                'X-Hub-Signature-256',
                signature
            );
        } else {
            req.headers.put(
                'X-Hub-Signature-256',
                'sha256=invalidsignature'
            );
        }

        RestContext.request = req;
        RestContext.response = res;
    }

     @IsTest
    static void testSuccessfulGetRequest() {

        prepareGetRequest(
            'WHATSAPPTOKEN',
            '123456789'
        );

        Test.startTest();
        WhatsAppWebhook.doGet();
        Test.stopTest();

        System.assertEquals(
            200,
            RestContext.response.statusCode,
            'Valid verification token should return 200'
        );

        System.assertEquals(
            '123456789',
            RestContext.response.responseBody.toString(),
            'Challenge should be returned'
        );
    }

    
    @IsTest
    static void testInvalidGetRequest() {

        prepareGetRequest(
            'INVALIDTOKEN',
            '123456789'
        );

        Test.startTest();
        WhatsAppWebhook.doGet();
        Test.stopTest();

        System.assertEquals(
            403,
            RestContext.response.statusCode,
            'Invalid token should return 403'
        );
    }

    
    @IsTest
    static void testGetWithoutChallenge() {

        prepareGetRequest(
            'WHATSAPPTOKEN',
            null
        );

        Test.startTest();
        WhatsAppWebhook.doGet();
        Test.stopTest();

        System.assertEquals(
            403,
            RestContext.response.statusCode
        );
    }

    
    @IsTest
    static void testInvalidPostSignature() {

        String body = '{"object":"whatsapp_business_account"}';

        preparePostRequest(body, false);

        Test.startTest();
        WhatsAppWebhook.doPost();
        Test.stopTest();

        System.assertEquals(
            401,
            RestContext.response.statusCode,
            'Invalid signature should return 401'
        );

        System.assertEquals(
            '{"success":false,"message":"Signature could not be verified"}',
            RestContext.response.responseBody.toString()
        );
    }

   
    @IsTest
    static void testTextMessagePost() {

        String payload =
            '{' +
                '"object":"whatsapp_business_account",' +
                '"entry":[' +
                    '{' +
                        '"changes":[' +
                            '{' +
                                '"value":{' +
                                    '"metadata":{' +
                                        '"display_phone_number":"919876543210"' +
                                    '},' +
                                    '"contacts":[' +
                                        '{' +
                                            '"profile":{' +
                                                '"name":"Test Customer"' +
                                            '},' +
                                            '"wa_id":"919876500001"' +
                                        '}' +
                                    '],' +
                                    '"messages":[' +
                                        '{' +
                                            '"from":"919876500001",' +
                                            '"id":"wamid.TEST001",' +
                                            '"timestamp":"1730000000",' +
                                            '"type":"text",' +
                                            '"text":{' +
                                                '"body":"Hello Salesforce"' +
                                            '}' +
                                        '}' +
                                    ']' +
                                '}' +
                            '}' +
                        ']' +
                    '}' +
                ']' +
            '}';

        preparePostRequest(payload, true);

        Test.startTest();
        WhatsAppWebhook.doPost();
        Test.stopTest();

        System.assertEquals(
            200,
            RestContext.response.statusCode
        );

        System.assertEquals(
            '{"success":true}',
            RestContext.response.responseBody.toString()
        );

        List<WhatsApp_Message__c> messages = [
            SELECT Id,
                   Business_Phone_Number__c,
                   Customer_Phone__c,
                   Customer_Name__c,
                   Message_ID__c,
                   Message_Type__c,
                   Message_Content__c,
                   Message_Sent_Time__c
            FROM WhatsApp_Message__c
            WHERE Message_ID__c = 'wamid.TEST001'
        ];

        System.assertEquals(
            1,
            messages.size(),
            'One WhatsApp message should be created'
        );

        System.assertEquals(
            '919876500001',
            messages[0].Customer_Phone__c
        );

        System.assertEquals(
            'Test Customer',
            messages[0].Customer_Name__c
        );

        System.assertEquals(
            'Hello Salesforce',
            messages[0].Message_Content__c
        );

        System.assertEquals(
            'text',
            messages[0].Message_Type__c
        );
    }

   
    @IsTest
    static void testImageMessagePost() {

        String payload =
            '{' +
                '"entry":[' +
                    '{' +
                        '"changes":[' +
                            '{' +
                                '"value":{' +
                                    '"metadata":{' +
                                        '"display_phone_number":"919876543210"' +
                                    '},' +
                                    '"messages":[' +
                                        '{' +
                                            '"from":"919876500002",' +
                                            '"id":"wamid.IMAGE001",' +
                                            '"timestamp":"1730000000",' +
                                            '"type":"image",' +
                                            '"image":{' +
                                                '"id":"MEDIA001",' +
                                                '"mime_type":"image/jpeg",' +
                                                '"sha256":"ABC123"' +
                                            '}' +
                                        '}' +
                                    ']' +
                                '}' +
                            '}' +
                        ']' +
                    '}' +
                ']' +
            '}';

        preparePostRequest(payload, true);

        Test.startTest();
        WhatsAppWebhook.doPost();
        Test.stopTest();

        WhatsApp_Message__c savedMessage = [
            SELECT Id,
                   Image_ID__c,
                   Image_Type__c,
                   Image_SHA_256__c,
                   Customer_Phone__c
            FROM WhatsApp_Message__c
            WHERE Message_ID__c = 'wamid.IMAGE001'
            LIMIT 1
        ];

        System.assertEquals('MEDIA001', savedMessage.Image_ID__c);
        System.assertEquals('image/jpeg', savedMessage.Image_Type__c);
        System.assertEquals('ABC123', savedMessage.Image_SHA_256__c);
    }

    // ------------------------------------------------
    // Test 7: Reaction message
    // ------------------------------------------------
    @IsTest
    static void testReactionMessagePost() {

        String payload =
            '{' +
                '"entry":[' +
                    '{' +
                        '"changes":[' +
                            '{' +
                                '"value":{' +
                                    '"messages":[' +
                                        '{' +
                                            '"from":"919876500003",' +
                                            '"id":"wamid.REACTION001",' +
                                            '"timestamp":"1730000000",' +
                                            '"type":"reaction",' +
                                            '"reaction":{' +
                                                '"emoji":"👍",' +
                                                '"message_id":"wamid.PARENT001"' +
                                            '}' +
                                        '}' +
                                    ']' +
                                '}' +
                            '}' +
                        ']' +
                    '}' +
                ']' +
            '}';

        preparePostRequest(payload, true);

        Test.startTest();
        WhatsAppWebhook.doPost();
        Test.stopTest();

        WhatsApp_Message__c savedMessage = [
            SELECT Id,
                   Reaction__c,
                   Parent_Message_ID__c
            FROM WhatsApp_Message__c
            WHERE Message_ID__c = 'wamid.REACTION001'
            LIMIT 1
        ];

        System.assertEquals('👍', savedMessage.Reaction__c);

        System.assertEquals(
            'wamid.PARENT001',
            savedMessage.Parent_Message_ID__c
        );
    }

    
    @IsTest
    static void testContextMessagePost() {

        String payload =
            '{' +
                '"entry":[' +
                    '{' +
                        '"changes":[' +
                            '{' +
                                '"value":{' +
                                    '"messages":[' +
                                        '{' +
                                            '"from":"919876500004",' +
                                            '"id":"wamid.CONTEXT001",' +
                                            '"timestamp":"1730000000",' +
                                            '"type":"text",' +
                                            '"text":{' +
                                                '"body":"Reply message"' +
                                            '},' +
                                            '"context":{' +
                                                '"id":"wamid.ORIGINAL001"' +
                                            '}' +
                                        '}' +
                                    ']' +
                                '}' +
                            '}' +
                        ']' +
                    '}' +
                ']' +
            '}';

        preparePostRequest(payload, true);

        Test.startTest();
        WhatsAppWebhook.doPost();
        Test.stopTest();

        WhatsApp_Message__c savedMessage = [
            SELECT Id,
                   Parent_Message_ID__c
            FROM WhatsApp_Message__c
            WHERE Message_ID__c = 'wamid.CONTEXT001'
            LIMIT 1
        ];

        System.assertEquals(
            'wamid.ORIGINAL001',
            savedMessage.Parent_Message_ID__c
        );
    }

  
    @IsTest
    static void testStatusEventPost() {

        String payload =
            '{' +
                '"entry":[' +
                    '{' +
                        '"changes":[' +
                            '{' +
                                '"value":{' +
                                    '"statuses":[' +
                                        '{' +
                                            '"id":"wamid.STATUS001",' +
                                            '"status":"delivered"' +
                                        '}' +
                                    ']' +
                                '}' +
                            '}' +
                        ']' +
                    '}' +
                ']' +
            '}';

        preparePostRequest(payload, true);

        Test.startTest();
        WhatsAppWebhook.doPost();
        Test.stopTest();

        System.assertEquals(
            200,
            RestContext.response.statusCode
        );

        System.assertEquals(
            0,
            [SELECT COUNT()
             FROM WhatsApp_Message__c
             WHERE Message_ID__c = 'wamid.STATUS001']
        );
    }

    
    @IsTest
    static void testPostWithoutEntry() {

        String payload =
            '{"object":"whatsapp_business_account"}';

        preparePostRequest(payload, true);

        Test.startTest();
        WhatsAppWebhook.doPost();
        Test.stopTest();

        System.assertEquals(
            200,
            RestContext.response.statusCode
        );

        System.assertEquals(
            '{"success":true}',
            RestContext.response.responseBody.toString()
        );
    }

 
    @IsTest
    static void testInvalidJsonPayload() {

        String payload = '{invalid-json';

        preparePostRequest(payload, true);

        Test.startTest();
        WhatsAppWebhook.doPost();
        Test.stopTest();

        System.assertEquals(
            200,
            RestContext.response.statusCode,
            'Webhook catches processing exceptions and returns 200'
        );

        System.assertEquals(
            '{"success":true}',
            RestContext.response.responseBody.toString()
        );
    }

 
    @IsTest
    static void testMissingSignature() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/whatsapp/webhooks/v1/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{}');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        WhatsAppWebhook.doPost();
        Test.stopTest();

        System.assertEquals(
            401,
            RestContext.response.statusCode
        );
    }
}