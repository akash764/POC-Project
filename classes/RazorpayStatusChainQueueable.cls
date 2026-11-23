public class RazorpayStatusChainQueueable implements Queueable, Database.AllowsCallouts {
    private Id paymentId;
    private Integer attempt;
    private static final Integer MAX_ATTEMPTS = 30;   // 30 x 2 minutes = 1 hour of checking
    private static final Integer DELAY_MINUTES = 2;

    public RazorpayStatusChainQueueable(Id paymentId, Integer attempt) {
        this.paymentId = paymentId;
        this.attempt = attempt;
    }

    public void execute(QueueableContext ctx) {
        Payment__c p = [SELECT Id, Status__c, Amount__c, Payment_Link_ID__c
                        FROM Payment__c WHERE Id = :paymentId];

        // webhook (or someone) already handled it, or there is no link to check
        if (p.Status__c != 'Pending' || String.isBlank(p.Payment_Link_ID__c)) return;

        // 1. Ask Razorpay (callout first, DML after)
        String linkStatus;
        Map<String, Object> body;
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:RazorPayNamedCredentials/v1/payment_links/' + p.Payment_Link_ID__c);
            req.setMethod('GET');
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200) {
                body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                linkStatus = (String) body.get('status');   // created, paid, expired, cancelled
            }
        } catch (Exception e) {
            System.debug('Razorpay status check error: ' + e.getMessage());
        }

        // 2. Paid: verify the amount, then mark Success
        if (linkStatus == 'paid') {
            Long paidPaise = Long.valueOf(String.valueOf(body.get('amount_paid')));
            if (paidPaise == (p.Amount__c * 100).longValue()) {
                p.Status__c       = 'Success';
                p.Payment_Date__c = Date.today();
                List<Object> pays = (List<Object>) body.get('payments');
                if (pays != null && !pays.isEmpty()) {
                    p.Gateway_Payment_ID__c = (String) ((Map<String, Object>) pays[0]).get('payment_id');
                }
            } else {
                p.Error_Message__c = 'Amount mismatch: paid ' + paidPaise + ' paise';
            }
            update p;
            return;
        }

        // 3. Expired or cancelled: Failed
        if (linkStatus == 'expired' || linkStatus == 'cancelled') {
            p.Status__c = 'Failed';
            update p;
            return;
        }

        // 4. Still unpaid (or the check failed): look again later
        if (attempt < MAX_ATTEMPTS) {
            System.enqueueJob(new RazorpayStatusChainQueueable(paymentId, attempt + 1), DELAY_MINUTES);
        }
    }
}