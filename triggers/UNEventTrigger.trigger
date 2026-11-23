/**
 * @description Trigger on standard Event object to automate UrbanNest site visit logistics.
 */
trigger UNEventTrigger on Event (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            UNEventTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            UNEventTriggerHandler.handleBeforeUpdate(Trigger.new);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            UNEventTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            UNEventTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}