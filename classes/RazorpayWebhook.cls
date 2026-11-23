@RestResource(urlMapping='/razorpay/webhooks/v1/*')
global without sharing class RazorpayWebhook {

    @HttpPost
    global static void handle() {
        RestRequest req  = RestContext.request;
        RestResponse res = RestContext.response;
        String body = req.requestBody.toString();

        String signature;
        for (String h : req.headers.keySet()) {
            if (h.equalsIgnoreCase('X-Razorpay-Signature')) signature = req.headers.get(h);
        }
        Blob mac = Crypto.generateMac('hmacSHA256',
            Blob.valueOf(body), Blob.valueOf(Label.RazorpayWebhookSecret));
        if (signature == null || EncodingUtil.convertToHex(mac) != signature) {
            System.debug(LoggingLevel.ERROR, 'Razorpay webhook: signature mismatch');
            res.statusCode = 401;
            return;
        }

        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(body);
            String event = (String) root.get('event');
            Map<String, Object> payload = (Map<String, Object>) root.get('payload');
            System.debug('Razorpay webhook event: ' + event);

            if (event == 'payment_link.paid') {
                handlePaid(payload);
            } else if (event == 'payment_link.expired' || event == 'payment_link.cancelled') {
                handleLinkClosed(payload);
            } else if (event == 'payment.failed') {
                handleFailed(payload);
            } else if (event == 'refund.processed') {
                handleRefundResult(payload, true);
            } else if (event == 'refund.failed') {
                handleRefundResult(payload, false);
            }
            res.statusCode = 200;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Razorpay webhook error: '
                + e.getMessage() + ' | ' + e.getStackTraceString());
            res.statusCode = 500;
        }
    }

    private static Map<String, Object> entity(Map<String, Object> payload, String key) {
        if (payload == null) return null;
        Map<String, Object> wrapper = (Map<String, Object>) payload.get(key);
        return wrapper == null ? null : (Map<String, Object>) wrapper.get('entity');
    }

    private static Id toId(Object value) {
        try { return value == null ? null : Id.valueOf(String.valueOf(value)); }
        catch (Exception e) { return null; }
    }

    private static void handlePaid(Map<String, Object> payload) {
        Map<String, Object> link = entity(payload, 'payment_link');
        Map<String, Object> pay  = entity(payload, 'payment');
        Id recId = toId(link == null ? null : link.get('reference_id'));
        if (recId == null || pay == null) return;

        List<Payment__c> found = [SELECT Id, Status__c, Amount__c
                                  FROM Payment__c WHERE Id = :recId LIMIT 1];
        if (found.isEmpty() || found[0].Status__c == 'Success') return;
        Payment__c p = found[0];

        Long paidPaise = Long.valueOf(String.valueOf(pay.get('amount')));
        if (p.Amount__c == null || paidPaise != (p.Amount__c * 100).longValue()) {
            p.Error_Message__c = 'Amount mismatch: received ' + paidPaise + ' paise';
            update p;
            return;
        }

        Long createdAt = Long.valueOf(String.valueOf(pay.get('created_at')));
        p.Status__c             = 'Success';
        p.Gateway_Payment_ID__c = (String) pay.get('id');
        p.Payment_Date__c       = DateTime.newInstance(createdAt * 1000L).date();
        update p;
    }

    private static void handleLinkClosed(Map<String, Object> payload) {
        Map<String, Object> link = entity(payload, 'payment_link');
        Id recId = toId(link == null ? null : link.get('reference_id'));
        if (recId == null) return;

        List<Payment__c> found = [SELECT Id, Status__c FROM Payment__c WHERE Id = :recId LIMIT 1];
        if (!found.isEmpty() && found[0].Status__c == 'Pending') {
            found[0].Status__c = 'Failed';
            update found[0];
        }
    }

    private static void handleFailed(Map<String, Object> payload) {
        Map<String, Object> pay = entity(payload, 'payment');
        if (pay == null) return;
        Map<String, Object> notes = pay.get('notes') instanceof Map<String, Object>
            ? (Map<String, Object>) pay.get('notes') : null;
        Id recId = toId(notes == null ? null : notes.get('payment_id'));
        if (recId == null) return;

        List<Payment__c> found = [SELECT Id, Status__c FROM Payment__c WHERE Id = :recId LIMIT 1];
        if (!found.isEmpty() && found[0].Status__c == 'Pending') {
            found[0].Error_Message__c = (String) pay.get('error_description');
            update found[0];
        }
    }

    private static void handleRefundResult(Map<String, Object> payload, Boolean ok) {
        Map<String, Object> refund = entity(payload, 'refund');
        if (refund == null) return;

        List<Payment__c> found = [
            SELECT Id, Amount__c, Booking__c FROM Payment__c
            WHERE Gateway_Payment_ID__c = :(String) refund.get('payment_id') LIMIT 1
        ];
        if (found.isEmpty()) return;

        Payment__c p = found[0];
        Decimal refunded = Decimal.valueOf(String.valueOf(refund.get('amount'))).divide(100, 2);
        if (ok && refunded >= p.Amount__c) {
            p.Status__c = 'Refunded';
            update p;
        }
        update new Booking__c(Id = p.Booking__c, Refund_Status__c = ok ? 'Processed' : 'Failed');
    }
}