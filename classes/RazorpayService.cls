public with sharing class RazorpayService {

    public class LinkResult {
        public Boolean success = false;
        public String linkId;
        public String shortUrl;
        public String error;
    }

    public class RefundResult {
        public Boolean success = false;
        public String refundId;
        public String status;
        public String error;
    }

    // 9876543210 -> +919876543210
    public static String normalizePhone(String raw) {
        if (String.isBlank(raw)) return null;
        String digits = raw.replaceAll('[^0-9]', '');
        if (digits.length() == 10) digits = '91' + digits;
        if (digits.startsWith('0') && digits.length() == 11) digits = '91' + digits.substring(1);
        return '+' + digits;
    }

    public static LinkResult createPaymentLink(
        Id paymentId, Decimal amount, String name,
        String phone, String email, String description, Boolean upiOnly
    ) {
        LinkResult result = new LinkResult();
        if (amount == null || amount <= 0) {
            result.error = 'Amount must be greater than zero';
            return result;
        }

        Map<String, Object> customer = new Map<String, Object>();
        if (String.isNotBlank(name))  customer.put('name', name);
        if (String.isNotBlank(email)) customer.put('email', email);
        String contact = normalizePhone(phone);
        if (contact != null)          customer.put('contact', contact);

        Map<String, Object> payload = new Map<String, Object>{
            'amount'       => (amount * 100).setScale(0).longValue(),   // paise
            'currency'     => 'INR',
            'description'  => description,
            'reference_id' => String.valueOf(paymentId),
            'expire_by'    => (DateTime.now().addDays(14).getTime() / 1000),
            'notify'       => new Map<String, Object>{ 'sms' => false, 'email' => false },
            'notes'        => new Map<String, Object>{ 'payment_id' => String.valueOf(paymentId) }
        };
        if (!customer.isEmpty()) payload.put('customer', customer);
        //if (upiOnly == true)     payload.put('upi_link', true);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:RazorPayNamedCredentials/v1/payment_links');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> body =
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                result.success  = true;
                result.linkId   = (String) body.get('id');
                result.shortUrl = (String) body.get('short_url');
            } else {
                result.error = res.getStatusCode() + ': ' + res.getBody();
            }
        } catch (Exception e) {
            result.error = 'Exception: ' + e.getMessage();
        }
        return result;
    }

    public static RefundResult createRefund(String razorpayPaymentId, Decimal amount, Id paymentRecordId) {
        RefundResult result = new RefundResult();
        if (String.isBlank(razorpayPaymentId) || amount == null || amount <= 0) {
            result.error = 'Missing payment id or invalid amount';
            return result;
        }

        Map<String, Object> payload = new Map<String, Object>{
            'amount' => (amount * 100).setScale(0).longValue(),
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
                Map<String, Object> body =
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                result.success  = true;
                result.refundId = (String) body.get('id');
                result.status   = (String) body.get('status');
            } else {
                result.error = res.getStatusCode() + ': ' + res.getBody();
            }
        } catch (Exception e) {
            result.error = 'Exception: ' + e.getMessage();
        }
        return result;
    }
}