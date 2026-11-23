public class WhatsAppUtils {

    private static final String API_VERSION     = 'v25.0';
    private static final String PHONE_NUMBER_ID = '1420809057784255';

    
    @future(callout=true)
    public static void sendTextMessageAsync(String messageContent, String toPhone) {
        sendTextMessage(messageContent, toPhone);
    }

    
    public static Boolean sendTextMessage(String messageContent, String toPhone) {
        
        String cleanPhone = toPhone == null ? '' : toPhone.replaceAll('[^0-9]', '');
        if (String.isBlank(cleanPhone) || String.isBlank(messageContent)) {
            return false;
        }

        
        Map<String, Object> payload = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'recipient_type'    => 'individual',
            'to'                => cleanPhone,
            'type'              => 'text',
            'text'              => new Map<String, Object>{
                'preview_url' => false,
                'body'        => messageContent
            }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://graph.facebook.com/' + API_VERSION + '/' + PHONE_NUMBER_ID + '/messages');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + System.Label.PERMANANTWHATSAPPTOKEN.trim());
        req.setBody(JSON.serialize(payload));
        req.setTimeout(20000);

        try {
            HttpResponse res = new Http().send(req);

            
            System.debug(LoggingLevel.ERROR, 'WA send status: ' + res.getStatusCode());
            System.debug(LoggingLevel.ERROR, 'WA send body: ' + res.getBody());

            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                return false; 
            }

            SendResponse parsed = (SendResponse) JSON.deserialize(res.getBody(), SendResponse.class);
            if (parsed.messages == null || parsed.messages.isEmpty()) {
                System.debug(LoggingLevel.ERROR, 'WA send: no message id in response');
                return false;
            }

            WhatsApp_Message__c rec = new WhatsApp_Message__c();
            rec.Message_Content__c = messageContent;
            rec.Customer_Phone__c = cleanPhone;
            rec.Message_ID__c = parsed.messages[0].id;
            rec.Message_Sent_Time__c = System.now();
            rec.Outgoing__c = true;
            rec.AgentName__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

            Database.UpsertResult ur = Database.upsert(rec, WhatsApp_Message__c.Message_ID__c, false);
            if (ur.isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'WA send saved: ' + rec.Id);
            } else {
                
                System.debug(LoggingLevel.ERROR, 'WA send save failed: ' + ur.getErrors());
            }
            return true;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'WA send exception: ' + ex.getTypeName() + ' - ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
            return false;
        }
    }

    public class SendResponse {
        public String messaging_product;
        public List<Msg> messages;
    }

    public class Msg {
        public String id;
    }
}