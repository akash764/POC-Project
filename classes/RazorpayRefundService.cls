public with sharing class RazorpayRefundService {

    public class RefundResult {
        public Boolean success = false;
        public String refundId;
        public String status;
        public String error;
    }

    public static RefundResult createRefund(String razorpayPaymentId, Decimal amount, Id paymentRecordId) {
        RefundResult result = new RefundResult();

        Map<String, Object> payload = new Map<String, Object>{
            'amount' => (amount * 100).setScale(0).longValue(), // paise
            'speed'  => 'normal',
            'notes'  => new Map<String, Object>{ 'payment_record_id' => String.valueOf(paymentRecordId) }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:RazorPayNamedCredentials/v1/payments/' + razorpayPaymentId + '/refund');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                result.success  = true;
                result.refundId = (String) body.get('id');
                result.status   = (String) body.get('status'); // pending / processed / failed
            } else {
                result.error = res.getStatusCode() + ': ' + res.getBody();
            }
        } catch (Exception e) {
            result.error = e.getMessage();
        }
        return result;
    }
}