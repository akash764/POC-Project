public class RazorpayRefundQueueable implements Queueable, Database.AllowsCallouts {
    private Id paymentId;
    private Decimal amount;

    public RazorpayRefundQueueable(Id paymentId, Decimal amount) {
        this.paymentId = paymentId; this.amount = amount;
    }

    public void execute(QueueableContext ctx) {
        Payment__c p = [SELECT Id, Booking__c, Gateway_Payment_ID__c
                        FROM Payment__c WHERE Id = :paymentId];

        RazorpayRefundService.RefundResult r =
            RazorpayRefundService.createRefund(p.Gateway_Payment_ID__c, amount, p.Id);

        Booking__c b = new Booking__c(Id = p.Booking__c);
        if (r.success) {
            p.Refund_ID__c = r.refundId;
            b.Refund_Status__c = 'Processing';
            update p;
        } else {
            p.Error_Message__c = r.error;
            b.Refund_Status__c = 'Failed';
            update p;
        }
        update b;
    }
}