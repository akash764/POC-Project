public class RazorpayWebhookTester {

    // Builds a signed webhook call and runs your real RazorpayWebhook.handle()
    public static Integer send(String event, Map<String, Object> payload) {
        String body = JSON.serialize(new Map<String, Object>{
            'event' => event, 'payload' => payload
        });
        Blob mac = Crypto.generateMac('hmacSHA256',
            Blob.valueOf(body), Blob.valueOf(Label.RazorpayWebhookSecret));

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(body);
        req.addHeader('X-Razorpay-Signature', EncodingUtil.convertToHex(mac));
        RestResponse res = new RestResponse();
        RestContext.request  = req;
        RestContext.response = res;

        RazorpayWebhook.handle();
        return res.statusCode;
    }

    public static Integer paid(Id paymentId) {
        return send('payment_link.paid', new Map<String, Object>{
            'payment_link' => new Map<String, Object>{ 'entity' => new Map<String, Object>{
                'id' => 'plink_TEST', 'reference_id' => String.valueOf(paymentId) } },
            'payment' => new Map<String, Object>{ 'entity' => new Map<String, Object>{
                'id' => 'pay_TEST' + Math.abs(Crypto.getRandomInteger()),
                'created_at' => Datetime.now().getTime() / 1000 } }
        });
    }

    public static Integer attemptFailed(Id paymentId) {
        return send('payment.failed', new Map<String, Object>{
            'payment' => new Map<String, Object>{ 'entity' => new Map<String, Object>{
                'id' => 'pay_FAILTEST',
                'error_description' => 'Payment failed due to bank decline',
                'notes' => new Map<String, Object>{ 'payment_id' => String.valueOf(paymentId) } } }
        });
    }

    public static Integer linkClosed(Id paymentId, Boolean expired) {
        return send(expired ? 'payment_link.expired' : 'payment_link.cancelled',
            new Map<String, Object>{
                'payment_link' => new Map<String, Object>{ 'entity' => new Map<String, Object>{
                    'id' => 'plink_TEST', 'reference_id' => String.valueOf(paymentId) } }
            });
    }

    public static Integer refund(String gatewayPaymentId, Decimal rupees, Boolean ok) {
        return send(ok ? 'refund.processed' : 'refund.failed', new Map<String, Object>{
            'refund' => new Map<String, Object>{ 'entity' => new Map<String, Object>{
                'id' => 'rfnd_TEST', 'payment_id' => gatewayPaymentId,
                'amount' => (rupees * 100).longValue() } }
        });
    }
}