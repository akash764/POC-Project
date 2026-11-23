public class RazorpayRefundAction {

    public class Request {
        @InvocableVariable(required=true) public Id bookingId;
        @InvocableVariable(required=true) public Decimal refundAmount;
    }

    @InvocableMethod(label='Create Razorpay Refund')
    public static void refund(List<Request> requests) {
        for (Request r : requests) {
            List<Payment__c> payments = [
                SELECT Id, Amount__c FROM Payment__c
                WHERE Booking__c = :r.bookingId
                  AND Status__c = 'Success'
                  AND Payment_Mode__c = 'Razorpay Online'
                  AND Gateway_Payment_ID__c != null
                ORDER BY Payment_Date__c DESC LIMIT 1
            ];
            if (payments.isEmpty() || r.refundAmount > payments[0].Amount__c) {
                continue; // see "Things to watch"
            }
            System.enqueueJob(new RazorpayRefundQueueable(payments[0].Id, r.refundAmount));
        }
    }
}