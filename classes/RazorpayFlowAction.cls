public class RazorpayFlowAction {

    public class Request {
        @InvocableVariable(required=true) public Id bookingId;
        @InvocableVariable(required=true) public Decimal amount;
        @InvocableVariable(required=true) public String paymentType;
        @InvocableVariable(required=true) public String customerName;
        @InvocableVariable(required=true) public String phone;
        @InvocableVariable public String email;
        @InvocableVariable public Boolean upiOnly;
    }

    @InvocableMethod(label='Create Razorpay Payment Link')
    public static void create(List<Request> requests) {
        List<Payment__c> payments = new List<Payment__c>();
        for (Request r : requests) {
            payments.add(new Payment__c(
                Booking__c      = r.bookingId,
                Amount__c       = r.amount,
                Payment_Type__c = r.paymentType,
                Payment_Mode__c = 'Razorpay Online',
                Status__c       = 'Pending'
            ));
        }
        insert payments;

        for (Integer i = 0; i < requests.size(); i++) {
            Request r = requests[i];
            System.enqueueJob(new RazorpayLinkQueueable(
                payments[i].Id, r.customerName, r.phone, r.email, r.upiOnly
            ));
        }
    }
}