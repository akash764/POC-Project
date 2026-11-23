public with sharing class WhatsAppLWCService {
    private static final String DEFAULT_COUNTRY_CODE = '91';

    private static String normalize(String phone) {
        String d = phone == null ? '' : phone.replaceAll('[^0-9]', '');
        if (d.length() == 10) d = DEFAULT_COUNTRY_CODE + d;
        return d;
    }

    @AuraEnabled(cacheable=true)
    public static List<WhatsApp_Message__c> listAllMessages(String customerPhone) {
        String p = normalize(customerPhone);
        if (String.isBlank(p)) return new List<WhatsApp_Message__c>();
        return [SELECT Id, Message_Content__c, Message_Type__c, Reaction__c,
                       Customer_Name__c, AgentName__c, Outgoing__c, Message_Sent_Time__c
                FROM WhatsApp_Message__c
                WHERE Customer_Phone__c = :p
                ORDER BY Message_Sent_Time__c ASC, CreatedDate ASC
                LIMIT 200];
    }

    @AuraEnabled
    public static void sendMessage(String customerPhone, String message) {
        String p = normalize(customerPhone);
        if (String.isBlank(p) || String.isBlank(message)) {
            throw new AuraHandledException('Phone and message are required.');
        }
        if (!WhatsAppUtils.sendTextMessage(message, p)) {
            throw new AuraHandledException('WhatsApp did not accept the message. Check the debug log for the Meta error.');
        }
    }
}