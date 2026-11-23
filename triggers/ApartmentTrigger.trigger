trigger ApartmentTrigger on Apartment__c (before insert, before update) {
    ApartmentTriggerHandler.checkDuplicateNames(Trigger.new, Trigger.oldMap);
}