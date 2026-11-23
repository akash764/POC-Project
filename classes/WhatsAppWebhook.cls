@RestResource(urlMapping='/whatsapp/webhooks/v1/*')
global without sharing class WhatsAppWebhook {
    
    private static final String VERIFY_TOKEN = 'WHATSAPPTOKEN';
    
    @HttpGet
    global static void doGet() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String token = request.params.get('hub.verify_token');
        String challenge = request.params.get('hub.challenge');
        System.debug(LoggingLevel.ERROR, 'WA GET params: ' + request.params);
        
        if (token == VERIFY_TOKEN && challenge != null) {
            response.statusCode = 200;
            response.addHeader('Content-Type', 'text/plain');
            response.responseBody = Blob.valueOf(challenge);
        } else {
            System.debug(LoggingLevel.ERROR, 'WA verify failed. Received token: [' + token + ']');
            response.statusCode = 403;
        }
    }
    
    @HttpPost
    global static void doPost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');
        
        
        System.debug(LoggingLevel.ERROR, 'WA webhook hit. Running user: ' + UserInfo.getUserName());
        
        if (!isSignatureValid(request)) {
            System.debug(LoggingLevel.ERROR, 'WA signature check FAILED');
            response.statusCode = 401;
            response.responseBody = Blob.valueOf('{"success":false,"message":"Signature could not be verified"}');
            return;
        }
        
        try {
            String body = request.requestBody.toString();
            System.debug(LoggingLevel.ERROR, 'WA payload: ' + body);
            
            
            body = body.replaceAll('"type"\\s*:', '"typex":')
                .replaceAll('"from"\\s*:', '"fromx":');
            
            WhatsAppMessage parent = (WhatsAppMessage) JSON.deserialize(body, WhatsAppMessage.class);
            List<WhatsApp_Message__c> records = new List<WhatsApp_Message__c>();
            
            if (parent.entry != null) {
                for (WhatsAppMessage.entry e : parent.entry) {
                    if (e.changes == null) continue;
                    for (WhatsAppMessage.changes c : e.changes) {
                        if (c.value == null || c.value.messages == null) continue; // e.g. status events
                        
                        Map<String, String> nameByWaId = new Map<String, String>();
                        if (c.value.contacts != null) {
                            for (WhatsAppMessage.contacts ct : c.value.contacts) {
                                nameByWaId.put(ct.wa_id, ct.profile != null ? ct.profile.name : null);
                            }
                        }
                        
                        for (WhatsAppMessage.messages m : c.value.messages) {
                            WhatsApp_Message__c rec = new WhatsApp_Message__c();
                            rec.Business_Phone_Number__c = c.value.metadata != null ? c.value.metadata.display_phone_number : null;
                            rec.Customer_Phone__c = m.fromx;
                            rec.Customer_Name__c = nameByWaId.get(m.fromx);
                            rec.Message_ID__c = m.id;
                            rec.Message_Type__c = m.typex;
                            rec.Message_Sent_Time__c = String.isNotBlank(m.timestamp)
                                ? Datetime.newInstance(Long.valueOf(m.timestamp) * 1000)
                                : System.now();
                            rec.Message_Content__c = m.text != null ? m.text.body : null;
                            
                            if (m.reaction != null) {
                                rec.Reaction__c = m.reaction.emoji;
                                rec.Parent_Message_ID__c = m.reaction.message_id;
                            }
                            if (m.image != null) {
                                rec.Image_ID__c = m.image.id;
                                rec.Image_Type__c = m.image.mime_type;
                                rec.Image_SHA_256__c = m.image.sha256;
                            }
                            
                            if (m.context != null) {
                                rec.Parent_Message_ID__c = m.context.id;
                            }
                            records.add(rec);
                        }
                    }
                }
            }
            
            if (!records.isEmpty()) {
                List<Database.SaveResult> results = Database.insert(records, false);
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        System.debug(LoggingLevel.ERROR, 'WA saved: ' + records[i].Id);
                    } else {
                        Database.Error err = results[i].getErrors()[0];
                        if (err.getStatusCode() == StatusCode.DUPLICATE_VALUE) {
                            System.debug(LoggingLevel.ERROR, 'WA duplicate ignored: ' + records[i].Message_ID__c);
                        } else {
                            System.debug(LoggingLevel.ERROR, 'WA insert failed: ' + results[i].getErrors());
                        }
                    }
                }
            }
        } catch (Exception ex) {
            
            System.debug(LoggingLevel.ERROR, 'WA processing error: ' + ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('{"success":true}');
    }
    
    private static Boolean isSignatureValid(RestRequest request) {
        String header;
        for (String k : request.headers.keySet()) {
            if (k.equalsIgnoreCase('X-Hub-Signature-256')) {
                header = request.headers.get(k);
            }
        }
        if (String.isBlank(header)) return false;
        
        
        Blob mac = Crypto.generateMac('hmacSHA256', request.requestBody,
                                      Blob.valueOf(System.Label.FBAppSecert.trim()));
        String expected = 'sha256=' + EncodingUtil.convertToHex(mac);
        return expected.equals(header);
    }
}