public class RazorpayReconcileJob implements Schedulable, Queueable, Database.AllowsCallouts {

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new RazorpayReconcileJob());   // callouts need a queueable
    }

    public void execute(QueueableContext qc) {
        reconcile();
    }

    public static void reconcile() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:RazorPayNamedCredentials/v1/payment_links?count=30');
        req.setMethod('GET');
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) return;
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        Map<Id, Map<String, Object>> paidByRecord = new Map<Id, Map<String, Object>>();
        for (Object o : (List<Object>) root.get('payment_links')) {
            Map<String, Object> l = (Map<String, Object>) o;
            if ('paid' != (String) l.get('status') || l.get('reference_id') == null) continue;
            try { paidByRecord.put(Id.valueOf((String) l.get('reference_id')), l); } catch (Exception e) {}
        }

        List<Payment__c> toUpdate = new List<Payment__c>();
        for (Payment__c p : [SELECT Id, Amount__c FROM Payment__c
                             WHERE Id IN :paidByRecord.keySet() AND Status__c = 'Pending']) {
            Map<String, Object> l = paidByRecord.get(p.Id);
            if (Long.valueOf(String.valueOf(l.get('amount_paid'))) != (p.Amount__c * 100).longValue()) continue;
            p.Status__c          = 'Success';
            p.Payment_Date__c    = Date.today();
            p.Payment_Link_ID__c = (String) l.get('id');
            List<Object> pays = (List<Object>) l.get('payments');
            if (pays != null && !pays.isEmpty()) {
                p.Gateway_Payment_ID__c = (String) ((Map<String, Object>) pays[0]).get('payment_id');
            }
            toUpdate.add(p);
        }
        if (!toUpdate.isEmpty()) update toUpdate;
    }
}