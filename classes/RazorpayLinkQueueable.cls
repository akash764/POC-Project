public class RazorpayLinkQueueable implements Queueable, Database.AllowsCallouts {
    private Id paymentId;
    private String name, phone, email;
    private Boolean upiOnly;
    private Integer attempt;

    public RazorpayLinkQueueable(Id paymentId, String name, String phone,
                                 String email, Boolean upiOnly) {
        this(paymentId, name, phone, email, upiOnly, 1);
    }

    public RazorpayLinkQueueable(Id paymentId, String name, String phone,
                                 String email, Boolean upiOnly, Integer attempt) {
        this.paymentId = paymentId; this.name = name;
        this.phone = phone; this.email = email;
        this.upiOnly = upiOnly; this.attempt = attempt;
    }

    public void execute(QueueableContext ctx) {
    Payment__c p = [SELECT Id, Amount__c, Payment_Type__c
                    FROM Payment__c WHERE Id = :paymentId];

    RazorpayService.LinkResult r = RazorpayService.createPaymentLink(
        p.Id, p.Amount__c, name, phone, email,
        'Property Booking - ' + p.Payment_Type__c, upiOnly
    );

    if (r.success) {
        p.Receipt_URL__c     = r.shortUrl;
        p.Payment_Link_ID__c = r.linkId;
        p.Error_Message__c   = null;
        update p;
        // start checking Razorpay for payment, first check in 2 minutes
        System.enqueueJob(new RazorpayStatusChainQueueable(p.Id, 1), 2);
        return;
    } else if (r.error != null && r.error.startsWith('429')
               && !r.error.contains('limit of') && attempt < 3) {
        System.enqueueJob(new RazorpayLinkQueueable(
            paymentId, name, phone, email, upiOnly, attempt + 1), 1);
        return;
    } else {
        p.Status__c        = 'Failed';
        p.Error_Message__c = r.error;
    }
    update p;
}
}