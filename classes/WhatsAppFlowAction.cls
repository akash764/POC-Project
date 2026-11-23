public with sharing class WhatsAppFlowAction {

    private static final String DEFAULT_COUNTRY_CODE = '91'; // change to your country code

    public class Request {
        @InvocableVariable(label='Phone' required=true)
        public String phone;
        @InvocableVariable(label='Message' required=true)
        public String message;
    }

    @InvocableMethod(label='Send WhatsApp Text' category='WhatsApp')
    public static void send(List<Request> requests) {
        for (Request r : requests) {
            String d = r.phone == null ? '' : r.phone.replaceAll('[^0-9]', '');
            if (d.length() == 10) d = DEFAULT_COUNTRY_CODE + d;
            if (String.isBlank(d) || String.isBlank(r.message)) continue;
            WhatsAppUtils.sendTextMessageAsync(r.message, d);
        }
    }
}