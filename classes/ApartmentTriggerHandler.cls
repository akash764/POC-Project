public without sharing class ApartmentTriggerHandler {

    private static String normalise(String s) {
        return s == null ? null : s.trim().toLowerCase();
    }

    private static String keyOf(Id projectId, String name) {
        return projectId + '|' + normalise(name);
    }

    public static void checkDuplicateNames(List<Apartment__c> newList, Map<Id, Apartment__c> oldMap) {

        // 1. Only check new records, or ones whose Name/Project changed
        List<Apartment__c> toCheck = new List<Apartment__c>();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> checkIds = new Set<Id>();

        for (Apartment__c a : newList) {
            if (a.Project__c == null || a.Name == null) continue;
            Apartment__c old = (oldMap == null || a.Id == null) ? null : oldMap.get(a.Id);
            if (old == null || a.Name != old.Name || a.Project__c != old.Project__c) {
                toCheck.add(a);
                projectIds.add(a.Project__c);
                if (a.Id != null) checkIds.add(a.Id);
            }
        }
        if (toCheck.isEmpty()) return;

        // 2. Lock the parent Project rows so concurrent saves are serialised
        List<Project__c> locked = [SELECT Id FROM Project__c WHERE Id IN :projectIds FOR UPDATE];

        // 3. Existing apartments in those projects (excluding ones being saved now)
        Map<String, Id> existing = new Map<String, Id>();
        for (Apartment__c ex : [SELECT Id, Name, Project__c
                                FROM Apartment__c
                                WHERE Project__c IN :projectIds
                                AND Id NOT IN :checkIds]) {
            existing.put(keyOf(ex.Project__c, ex.Name), ex.Id);
        }

        // 4. Compare against the database and against others in the same batch
        Set<String> seenInBatch = new Set<String>();
        for (Apartment__c a : toCheck) {
            String key = keyOf(a.Project__c, a.Name);
            Boolean dupInDb = existing.containsKey(key);
            Boolean dupInBatch = !seenInBatch.add(key);
            if (dupInDb || dupInBatch) {
                a.Name.addError('A block with this name already exists in this project.');
            }
        }
    }
}